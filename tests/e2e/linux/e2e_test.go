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

// Package linux is the Linux end-to-end suite. Each Groovy version runs in a
// disposable Ubuntu container: vfox is installed there, the plugin built from
// this repository is added, and the release is installed, used and run.
package linux

import (
	"fmt"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/version-fox/vfox-groovy/tests/e2e/common"
)

// TestE2E runs every version of common.Versions against the plugin in this
// repository. It needs Docker and the network, and it does not run with -short.
func TestE2E(t *testing.T) {
	if testing.Short() {
		t.Skip("the container E2E suite does not run with -short")
	}

	arch, err := vfoxArch(runtime.GOARCH)
	if err != nil {
		t.Fatal(err)
	}
	here, err := filepath.Abs(".")
	if err != nil {
		t.Fatal(err)
	}
	repoRoot := filepath.Join(here, "..", "..", "..")

	image := "vfox-groovy-e2e:linux-" + runtime.GOARCH
	if err := buildImage(here, image, arch); err != nil {
		t.Fatalf("build the image: %v", err)
	}

	plugin := filepath.Join(t.TempDir(), "groovy-plugin.zip")
	if err := common.BuildPluginZip(repoRoot, plugin); err != nil {
		t.Fatalf("build the plugin archive: %v", err)
	}

	for _, version := range common.Versions {
		t.Run(version, func(t *testing.T) {
			runVersion(t, image, plugin, version)
		})
	}
}

// vfoxArch maps a Go architecture to the name of vfox's Linux release archive.
func vfoxArch(goarch string) (string, error) {
	switch goarch {
	case "amd64":
		return "x86_64", nil
	case "arm64":
		return "aarch64", nil
	}
	return "", fmt.Errorf("no vfox release for linux/%s", goarch)
}

// buildImage builds the image from the Dockerfile in dir, for the vfox archive
// of arch, with the classic builder: the Dockerfile uses no BuildKit syntax.
func buildImage(dir, image, arch string) error {
	out, err := dockerOutput("build",
		"--tag", image,
		"--build-arg", "VFOX_ARCH="+arch,
		"--build-arg", "VFOX_VERSION="+common.VfoxVersion,
		"--file", filepath.Join(dir, "Dockerfile"),
		dir,
	)
	if err != nil {
		return fmt.Errorf("%w\n%s", err, out)
	}
	return nil
}
