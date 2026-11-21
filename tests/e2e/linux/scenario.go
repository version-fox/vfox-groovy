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

package linux

import (
	"strings"
	"testing"

	"github.com/version-fox/vfox-groovy/tests/e2e/common"
)

// activate sets up vfox's hooks, which `vfox use` needs. Each script starts a
// new shell, so it runs before every command that uses vfox.
const activate = `eval "$(vfox activate bash)"`

// load exports the environment of the current version into the shell:
// GROOVY_HOME, and the bin folder on PATH.
const load = `eval "$(vfox env -s bash)"`

// runVersion installs version through vfox, uses it and runs Groovy with it.
// Then it links the SDK the image's Debian package installs, runs that, and
// removes the link, which must leave the package's files alone.
func runVersion(t *testing.T, image, plugin, version string) {
	t.Helper()
	c := startContainer(t, image)
	c.copyIn(plugin, "/tmp/groovy-plugin.zip")

	c.must("add the plugin", "vfox add groovy --source /tmp/groovy-plugin.zip")

	info := c.must("vfox info groovy", "vfox info groovy")
	if !strings.Contains(info, common.ReadmeURL) {
		t.Fatalf("vfox info groovy should point to %s\n--- output ---\n%s", common.ReadmeURL, info)
	}

	search := c.must("vfox search groovy", "vfox search groovy")
	if err := common.CheckSearch(search, version); err != nil {
		t.Fatal(err)
	}

	install := c.retried("vfox install groovy@"+version, "vfox install groovy@"+version)
	if err := common.CheckInstall(version, install); err != nil {
		t.Fatal(err)
	}

	c.must("vfox use "+version, activate+"; vfox use --global groovy@"+version)
	run := c.must("groovy "+version,
		activate+"; "+load+`; echo "GROOVY_HOME=$GROOVY_HOME"; groovy -version; groovy -e 'println 6*7'`)
	if err := common.CheckGroovyVersion(run, version); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(run, "\n42") || !strings.Contains(run, "GROOVY_HOME=") ||
		!strings.Contains(run, "/.vfox/sdks/groovy") {
		t.Fatalf("groovy should run from vfox's SDK path\n--- output ---\n%s", run)
	}

	detected := c.must("vfox link --detect", "vfox link --detect -y groovy")
	linked, path, ok := common.LinkedVersion(detected)
	if !ok || path != common.SystemPackageHome {
		t.Fatalf("vfox link --detect should link the system package at %s\n--- output ---\n%s",
			common.SystemPackageHome, detected)
	}
	list := c.must("vfox list groovy", "vfox list groovy")
	if !strings.Contains(list, "(linked → "+common.SystemPackageHome+")") {
		t.Fatalf("vfox list groovy should mark %s as linked\n--- output ---\n%s", linked, list)
	}

	linkedRun := c.must("groovy "+linked+" (linked)",
		activate+"; vfox use --global groovy@"+linked+"; "+load+`; readlink -f "$GROOVY_HOME"; groovy -version`)
	if !strings.Contains(linkedRun, common.SystemPackageHome) {
		t.Fatalf("GROOVY_HOME should resolve to %s\n--- output ---\n%s", common.SystemPackageHome, linkedRun)
	}
	if err := common.CheckGroovyVersion(linkedRun, linked); err != nil {
		t.Fatal(err)
	}

	again := c.must("vfox link --detect again", "vfox link --detect -y groovy")
	if strings.Contains(again, "Linked ") || strings.Contains(again, "/.vfox/") {
		t.Fatalf("a second detection should link nothing new, and never vfox's own installs\n--- output ---\n%s", again)
	}

	c.must("vfox use "+version+" again", activate+"; vfox use --global groovy@"+version)
	c.must("vfox uninstall the link", activate+"; echo y | vfox uninstall groovy@"+linked)
	c.must("the system package stays", "test -x "+common.SystemPackageHome+"/bin/groovy")
}
