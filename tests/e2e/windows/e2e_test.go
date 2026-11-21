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

// Package windows is the Windows end-to-end suite. It runs on a Windows host,
// natively: the vfox release and a JDK are installed beforehand (the E2E
// workflow does it), and each Groovy version is installed, used and run
// through pwsh in a VFOX_HOME of its own.
package windows

import (
	"os/exec"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/version-fox/vfox-groovy/tests/e2e/common"
)

// TestE2E runs every version of common.Versions against the plugin in this
// repository. It needs vfox and pwsh on PATH, a JDK in JAVA_HOME and the
// network, and it does not run with -short.
func TestE2E(t *testing.T) {
	if testing.Short() {
		t.Skip("the Windows E2E suite does not run with -short")
	}
	if runtime.GOOS != "windows" {
		t.Skip("the Windows E2E suite runs on a Windows host")
	}
	for _, tool := range []string{"vfox", "pwsh"} {
		if _, err := exec.LookPath(tool); err != nil {
			t.Fatalf("%s must be on PATH: %v", tool, err)
		}
	}

	here, err := filepath.Abs(".")
	if err != nil {
		t.Fatal(err)
	}
	repoRoot := filepath.Join(here, "..", "..", "..")

	plugin := filepath.Join(tempDir(t), "groovy-plugin.zip")
	if err := common.BuildPluginZip(repoRoot, plugin); err != nil {
		t.Fatalf("build the plugin archive: %v", err)
	}

	for _, version := range common.Versions {
		t.Run(version, func(t *testing.T) {
			runVersion(t, plugin, version)
		})
	}
}
