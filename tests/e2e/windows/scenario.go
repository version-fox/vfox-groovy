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

package windows

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/version-fox/vfox-groovy/tests/e2e/common"
)

// activate loads vfox's PowerShell hook, which marks the session as one vfox
// can use. Each script runs in a new pwsh, so it comes before every command
// that uses vfox. The hook sets the console's encodings last, and that can
// throw in a process with no console, as a CI step is. The try keeps such a
// throw from ending the command line: the hook has already set its session
// marker by then, and `vfox use --global` does not need the hook anyway.
const activate = "try { vfox activate pwsh | Out-String | Invoke-Expression } catch { }"

// load exports the environment of the current version into the session:
// GROOVY_HOME, and the bin folder on PATH.
const load = "vfox env -s pwsh | Out-String | Invoke-Expression"

// fakeVersion is the version of the SDK the suite fakes for system detection,
// which the Windows host does not have. It is far newer than any release, so
// it cannot be mistaken for one.
const fakeVersion = "9.9.9"

// runVersion installs version through vfox, uses it and runs Groovy with it.
// Then it links an SDK that is on the machine but not installed by vfox, which
// the suite fakes in a folder of its own, and removes the link. The folder
// must survive the removal.
func runVersion(t *testing.T, plugin, version string) {
	t.Helper()
	dir := tempDir(t)
	s := &shell{t: t, home: dir}

	s.must("add the plugin", "vfox add groovy --source "+quote(plugin)+"; exit $LASTEXITCODE")

	info := s.must("vfox info groovy", "vfox info groovy; exit $LASTEXITCODE")
	if !strings.Contains(info, common.ReadmeURL) {
		t.Fatalf("vfox info groovy should point to %s\n--- output ---\n%s", common.ReadmeURL, info)
	}

	search := s.must("vfox search groovy", "vfox search groovy; exit $LASTEXITCODE")
	if err := common.CheckSearch(search, version); err != nil {
		t.Fatal(err)
	}

	install := s.retried("vfox install groovy@"+version, "vfox install groovy@"+version+"; exit $LASTEXITCODE")
	if err := common.CheckInstall(version, install); err != nil {
		t.Fatal(err)
	}

	s.must("vfox use "+version, activate+"; vfox use --global groovy@"+version+"; exit $LASTEXITCODE")
	run := s.must("groovy "+version, activate+"; "+load+"; "+
		`Write-Output ("GROOVY_HOME=" + $env:GROOVY_HOME); `+
		"groovy -version; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }; "+
		"groovy -e 'println 6*7'; exit $LASTEXITCODE")
	if err := common.CheckGroovyVersion(run, version); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(run, "\n42") || !strings.Contains(run, "GROOVY_HOME=") ||
		!strings.Contains(run, filepath.Join("sdks", "groovy")) {
		t.Fatalf("groovy should run from vfox's SDK path\n--- output ---\n%s", run)
	}

	fake := makeFakeSDK(t, dir)
	detected := s.must("vfox link --detect", "$env:GROOVY_HOME = "+quote(fake)+"; "+
		"vfox link --detect -y groovy; exit $LASTEXITCODE")
	linked, path, ok := common.LinkedVersion(detected)
	if !ok || linked != fakeVersion || !strings.Contains(path, "groovy-"+fakeVersion) {
		t.Fatalf("vfox link --detect should link the SDK at %s as %s\n--- output ---\n%s",
			fake, fakeVersion, detected)
	}

	list := s.must("vfox list groovy", "vfox list groovy; exit $LASTEXITCODE")
	if !strings.Contains(list, "linked") {
		t.Fatalf("vfox list groovy should mark %s as linked\n--- output ---\n%s", fakeVersion, list)
	}

	s.must("vfox uninstall the link", "'y' | vfox uninstall groovy@"+linked+"; exit $LASTEXITCODE")
	launcher := quote(filepath.Join(fake, "bin", "groovy.bat"))
	s.must("the SDK folder stays", "if (-not (Test-Path -LiteralPath "+launcher+")) { exit 1 }; exit 0")
}

// makeFakeSDK lays out a Groovy SDK at a folder of its own, with the launcher
// and the core jar of fakeVersion, and returns the folder.
func makeFakeSDK(t *testing.T, dir string) string {
	t.Helper()
	fake := filepath.Join(dir, "groovy-"+fakeVersion)
	for _, sub := range []string{"bin", "lib"} {
		if err := os.MkdirAll(filepath.Join(fake, sub), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(filepath.Join(fake, "bin", "groovy.bat"), []byte("@echo off\r\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(fake, "lib", "groovy-"+fakeVersion+".jar"), nil, 0o644); err != nil {
		t.Fatal(err)
	}
	return fake
}

// tempDir returns a directory for one run and removes it at the end of the
// test. Removal errors are ignored: on Windows a file that vfox still holds
// open must not fail a test that has already passed.
func tempDir(t *testing.T) string {
	t.Helper()
	dir, err := os.MkdirTemp("", "vfox-groovy-e2e-")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_ = os.RemoveAll(dir)
	})
	return dir
}
