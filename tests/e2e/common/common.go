// Copyright 2026 Han Li and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package common holds the logic the Linux and Windows suites share: the
// Groovy releases they install, what vfox must print for each step, and the
// plugin archive they add. Nothing here runs a shell or a container.
package common

import (
	"archive/zip"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// Versions are the Groovy releases the suites install, one run each. 4.0.22
// is the stable 4.x line. 2.4.5-incubating covers the incubator naming, whose
// SDK file has no suffix, and a release Apache checksums with an MD5 only. 6.0.0
// is the newest release without a pre-release suffix.
var Versions = []string{"4.0.22", "2.4.5-incubating", "6.0.0"}

// VfoxVersion is the vfox release the suites install. The workflows and the
// dev container pin it with the SHA-256 of each archive.
const VfoxVersion = "1.1.0"

// ReadmeURL is the README the plugin's notes point to.
const ReadmeURL = "https://github.com/version-fox/vfox-groovy/blob/main/README.md"

// SystemPackageHome is where the Debian and Ubuntu groovy package installs its
// SDK, which the Linux suite links with vfox link --detect.
const SystemPackageHome = "/usr/share/groovy"

// SDKVersion returns the version `groovy -version` prints for a release. The
// -incubating suffix names the directory only.
func SDKVersion(version string) string {
	return strings.TrimSuffix(version, "-incubating")
}

// Verified reports whether vfox verifies the download of a release. Apache
// publishes a SHA-256 for every release but the incubator ones, which publish
// an MD5 only.
func Verified(version string) bool {
	return !strings.HasSuffix(version, "-incubating")
}

var ansi = regexp.MustCompile(`\x1b\[[0-9;]*m`)

// StripANSI removes the colour codes vfox prints.
func StripANSI(s string) string {
	return ansi.ReplaceAllString(s, "")
}

var searchEntry = regexp.MustCompile(`^ - (\S+)`)

// SearchVersions returns the versions `vfox search groovy` lists, in the order
// it lists them, without the notes after each.
func SearchVersions(output string) []string {
	var versions []string
	for _, line := range strings.Split(StripANSI(output), "\n") {
		if match := searchEntry.FindStringSubmatch(strings.TrimRight(line, "\r")); match != nil {
			versions = append(versions, match[1])
		}
	}
	return versions
}

// IndexOf returns the position of item in list, or -1.
func IndexOf(list []string, item string) int {
	for i, candidate := range list {
		if candidate == item {
			return i
		}
	}
	return -1
}

// CheckSearch returns an error unless `vfox search groovy` lists version, and
// lists 6.0.0 before the release candidates of 6.0.0, which are older.
func CheckSearch(output, version string) error {
	list := SearchVersions(output)
	if IndexOf(list, version) < 0 {
		return fmt.Errorf("vfox search groovy does not list %s\n--- output ---\n%s", version, output)
	}
	release, candidate := IndexOf(list, "6.0.0"), IndexOf(list, "6.0.0-RC-1")
	if release >= 0 && candidate >= 0 && release > candidate {
		return fmt.Errorf("vfox search groovy lists 6.0.0-RC-1 before 6.0.0, so it is not newest first\n--- output ---\n%s", output)
	}
	return nil
}

var checksumLine = regexp.MustCompile(`Verifying checksum [0-9a-f]{64}`)

// CheckInstall returns an error unless `vfox install` reports version installed,
// and reports the download verified exactly when Apache publishes its checksum.
func CheckInstall(version, output string) error {
	out := StripANSI(output)
	if !strings.Contains(out, "Install groovy@"+version+" success") {
		return fmt.Errorf("vfox install groovy@%s did not report success\n--- output ---\n%s", version, output)
	}
	if Verified(version) {
		if !checksumLine.MatchString(out) {
			return fmt.Errorf("vfox install groovy@%s did not verify the download\n--- output ---\n%s", version, output)
		}
		return nil
	}
	if !strings.Contains(out, "Checksum is not provided") {
		return fmt.Errorf("vfox install groovy@%s should say that no checksum is provided\n--- output ---\n%s", version, output)
	}
	return nil
}

// CheckGroovyVersion returns an error unless the output of `groovy -version`
// names the SDK version of release.
func CheckGroovyVersion(output, version string) error {
	want := "Groovy Version: " + SDKVersion(version) + " "
	if !strings.Contains(StripANSI(output), want) {
		return fmt.Errorf("groovy -version should print %q\n--- output ---\n%s", want, output)
	}
	return nil
}

var linkedLine = regexp.MustCompile(`Linked groovy@(\S+) -> (\S+)`)

// LinkedVersion returns the version and the path of the first SDK that
// vfox link --detect linked, and whether it linked one.
func LinkedVersion(output string) (version, path string, ok bool) {
	match := linkedLine.FindStringSubmatch(StripANSI(output))
	if match == nil {
		return "", "", false
	}
	return match[1], match[2], true
}

// Result is the outcome of one command in a target: its exit code and its
// output, with both streams combined.
type Result struct {
	Code   int
	Output string
}

// OK reports whether the command exited with 0.
func (r Result) OK() bool {
	return r.Code == 0
}

// Retry runs attempt until it succeeds, at most attempts times, and waits a
// little longer after each failure. It is for the steps that download, since
// the archive is reached over the network. It returns the last result and error.
func Retry(attempts int, pause time.Duration, logf func(format string, args ...any), attempt func() (Result, error)) (Result, error) {
	var result Result
	var err error
	for i := 1; i <= attempts; i++ {
		result, err = attempt()
		if err == nil && result.OK() {
			return result, nil
		}
		if i < attempts {
			wait := pause * time.Duration(i)
			logf("attempt %d of %d failed (exit %d, error %v), retrying in %s", i, attempts, result.Code, err, wait)
			time.Sleep(wait)
		}
	}
	return result, err
}

// Name returns a name that no other run of the suites uses, for containers and
// directories. It is prefix, then the time in base 36.
func Name(prefix string) string {
	return prefix + "-" + strconv.FormatInt(time.Now().UnixNano(), 36)
}

// PluginFiles returns the files of the plugin that vfox reads, relative to the
// repository root: metadata.lua and the Lua files of hooks and lib. Tests, docs
// and CI are not part of the plugin.
func PluginFiles(repoRoot string) ([]string, error) {
	files := []string{"metadata.lua"}
	for _, dir := range []string{"hooks", "lib"} {
		matches, err := filepath.Glob(filepath.Join(repoRoot, dir, "*.lua"))
		if err != nil {
			return nil, err
		}
		for _, match := range matches {
			rel, err := filepath.Rel(repoRoot, match)
			if err != nil {
				return nil, err
			}
			files = append(files, filepath.ToSlash(rel))
		}
	}
	return files, nil
}

// BuildPluginZip writes the plugin to dst as a zip whose entries are the
// plugin's files under their paths in the repository, which is the layout
// `vfox add --source` reads.
func BuildPluginZip(repoRoot, dst string) (err error) {
	files, err := PluginFiles(repoRoot)
	if err != nil {
		return err
	}
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer func() {
		if closeErr := out.Close(); err == nil {
			err = closeErr
		}
	}()

	zw := zip.NewWriter(out)
	for _, rel := range files {
		if err := addFile(zw, filepath.Join(repoRoot, filepath.FromSlash(rel)), rel); err != nil {
			return err
		}
	}
	return zw.Close()
}

func addFile(zw *zip.Writer, path, name string) error {
	in, err := os.Open(path)
	if err != nil {
		return err
	}
	defer in.Close()
	w, err := zw.Create(name)
	if err != nil {
		return err
	}
	_, err = io.Copy(w, in)
	return err
}
