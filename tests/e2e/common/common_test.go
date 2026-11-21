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

package common

import (
	"archive/zip"
	"errors"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"
)

func TestSDKVersionAndVerified(t *testing.T) {
	cases := []struct {
		version  string
		sdk      string
		verified bool
	}{
		{"4.0.22", "4.0.22", true},
		{"6.0.0", "6.0.0", true},
		{"2.4.5-incubating", "2.4.5", false},
	}
	for _, c := range cases {
		if got := SDKVersion(c.version); got != c.sdk {
			t.Errorf("SDKVersion(%q) = %q, want %q", c.version, got, c.sdk)
		}
		if got := Verified(c.version); got != c.verified {
			t.Errorf("Verified(%q) = %v, want %v", c.version, got, c.verified)
		}
	}
}

// searchOutput is what vfox search groovy prints, colours and all.
const searchOutput = "\x1b[1mAvailable versions:\x1b[0m\n" +
	" - 6.0.0\n" +
	" - 6.0.0-RC-3 (pre-release)\n" +
	" - 6.0.0-RC-1 (pre-release)\n" +
	" - 2.4.5-incubating (incubating)\n"

func TestSearchVersions(t *testing.T) {
	got := SearchVersions(searchOutput)
	want := []string{"6.0.0", "6.0.0-RC-3", "6.0.0-RC-1", "2.4.5-incubating"}
	if !slices.Equal(got, want) {
		t.Fatalf("SearchVersions = %v, want %v", got, want)
	}
}

func TestCheckSearch(t *testing.T) {
	if err := CheckSearch(searchOutput, "2.4.5-incubating"); err != nil {
		t.Errorf("a listed version in newest-first order passed a check: %v", err)
	}
	if err := CheckSearch(searchOutput, "4.0.22"); err == nil {
		t.Error("a version the search does not list passed the check")
	}
	unsorted := " - 6.0.0-RC-1\n - 6.0.0\n - 4.0.22\n"
	if err := CheckSearch(unsorted, "4.0.22"); err == nil {
		t.Error("a 6.0.0-RC-1 listed before 6.0.0 passed the check")
	}
}

func TestCheckInstall(t *testing.T) {
	verified := "Preinstalling groovy@4.0.22...\n" +
		"Verifying checksum 17448950dea0280f708c778c43d0d1b41778ba58c5b4128a8ba1e7c0bed75bea...\n" +
		"Install groovy@4.0.22 success! \n"
	if err := CheckInstall("4.0.22", verified); err != nil {
		t.Errorf("a verified install passed: %v", err)
	}
	if err := CheckInstall("4.0.22", "Install groovy@4.0.22 success! \n"); err == nil {
		t.Error("an install without a checksum check passed for a release Apache publishes one for")
	}

	incubator := "Verifying checksum ...\nWARNING: Checksum is not provided, skip verify...\n" +
		"Install groovy@2.4.5-incubating success! \n"
	if err := CheckInstall("2.4.5-incubating", incubator); err != nil {
		t.Errorf("an incubator install without a checksum passed: %v", err)
	}
	if err := CheckInstall("2.4.5-incubating", verified); err == nil {
		t.Error("an incubator install that claims a verified checksum passed")
	}
	if err := CheckInstall("4.0.22", "error: 404 Not Found\n"); err == nil {
		t.Error("a failed install passed")
	}
}

func TestCheckGroovyVersion(t *testing.T) {
	out := "Groovy Version: 2.4.5 JVM: 21.0.13.1 Vendor: Ubuntu OS: Linux\n"
	if err := CheckGroovyVersion(out, "2.4.5-incubating"); err != nil {
		t.Errorf("the SDK version of an incubator release passed: %v", err)
	}
	if err := CheckGroovyVersion(out, "4.0.22"); err == nil {
		t.Error("another version passed")
	}
}

func TestLinkedVersion(t *testing.T) {
	out := "Found:\n  groovy@2.4.21  /usr/share/groovy  (system package)\n" +
		"Linked groovy@2.4.21 -> /usr/share/groovy\n"
	version, path, ok := LinkedVersion(out)
	if !ok || version != "2.4.21" || path != "/usr/share/groovy" {
		t.Fatalf("LinkedVersion = %q, %q, %v", version, path, ok)
	}
	if _, _, ok := LinkedVersion("No new groovy installations found.\n"); ok {
		t.Error("nothing linked, yet a link was reported")
	}
}

func TestRetry(t *testing.T) {
	logf := func(string, ...any) {}

	calls := 0
	result, err := Retry(3, 0, logf, func() (Result, error) {
		calls++
		if calls < 2 {
			return Result{Code: 1, Output: "timeout"}, nil
		}
		return Result{Output: "done"}, nil
	})
	if err != nil || !result.OK() || result.Output != "done" || calls != 2 {
		t.Fatalf("Retry after one failure: result %+v, error %v, calls %d", result, err, calls)
	}

	calls = 0
	boom := errors.New("docker is not running")
	result, err = Retry(2, 0, logf, func() (Result, error) {
		calls++
		return Result{}, boom
	})
	if !errors.Is(err, boom) || calls != 2 {
		t.Fatalf("Retry giving up: result %+v, error %v, calls %d", result, err, calls)
	}
}

func TestName(t *testing.T) {
	first := Name("vfox-groovy-e2e")
	time.Sleep(time.Millisecond)
	if second := Name("vfox-groovy-e2e"); first == second || !strings.HasPrefix(first, "vfox-groovy-e2e-") {
		t.Fatalf("Name returned %q then %q", first, second)
	}
}

func TestBuildPluginZip(t *testing.T) {
	repoRoot := filepath.Join("..", "..", "..")
	dst := filepath.Join(t.TempDir(), "groovy-plugin.zip")
	if err := BuildPluginZip(repoRoot, dst); err != nil {
		t.Fatalf("BuildPluginZip: %v", err)
	}
	reader, err := zip.OpenReader(dst)
	if err != nil {
		t.Fatalf("open the archive: %v", err)
	}
	defer reader.Close()

	var names []string
	for _, file := range reader.File {
		names = append(names, file.Name)
	}
	for _, want := range []string{"metadata.lua", "hooks/pre_install.lua", "hooks/detect.lua", "lib/util.lua", "lib/detect_groovy.lua"} {
		if !slices.Contains(names, want) {
			t.Errorf("the plugin archive lacks %s; it has %v", want, names)
		}
	}
	for _, name := range names {
		if strings.HasPrefix(name, "tests/") || strings.HasPrefix(name, "docs/") || strings.HasPrefix(name, ".") {
			t.Errorf("the plugin archive includes %s, which is not part of the plugin", name)
		}
	}
}
