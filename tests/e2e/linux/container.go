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
	"errors"
	"fmt"
	"os/exec"
	"testing"
	"time"

	"github.com/version-fox/vfox-groovy/tests/e2e/common"
)

// dockerOutput runs the docker CLI and returns its combined output.
func dockerOutput(args ...string) (string, error) {
	out, err := exec.Command("docker", args...).CombinedOutput()
	return string(out), err
}

// container is one disposable container that a version's steps run in.
type container struct {
	name string
	t    *testing.T
}

// startContainer starts image as a container that sleeps until the test ends,
// and removes the container when the test ends, whatever its outcome.
func startContainer(t *testing.T, image string) *container {
	t.Helper()
	name := common.Name("vfox-groovy-e2e")
	if out, err := dockerOutput("run", "--detach", "--name", name, image, "sleep", "infinity"); err != nil {
		t.Fatalf("start a container from %s: %v\n%s", image, err, out)
	}
	t.Cleanup(func() {
		if out, err := dockerOutput("rm", "--force", name); err != nil {
			t.Logf("remove container %s: %v\n%s", name, err, out)
		}
	})
	return &container{name: name, t: t}
}

// copyIn copies a file from the host into the container.
func (c *container) copyIn(src, dst string) {
	c.t.Helper()
	if out, err := dockerOutput("cp", src, c.name+":"+dst); err != nil {
		c.t.Fatalf("copy %s into the container: %v\n%s", src, err, out)
	}
}

// run runs script with bash in the container. A script that exits non-zero is
// a result with its exit code; an error means docker could not run it at all.
func (c *container) run(script string) (common.Result, error) {
	out, err := exec.Command("docker", "exec", c.name, "bash", "-c", script).CombinedOutput()
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		return common.Result{Code: exitErr.ExitCode(), Output: string(out)}, nil
	}
	if err != nil {
		return common.Result{}, fmt.Errorf("docker exec: %w", err)
	}
	return common.Result{Code: 0, Output: string(out)}, nil
}

// must runs script under label and fails the test unless it exits 0. It
// returns the output.
func (c *container) must(label, script string) string {
	c.t.Helper()
	result, err := c.run(script)
	if err != nil || !result.OK() {
		c.t.Fatalf("%s failed (exit %d, error %v)\n--- script ---\n%s\n--- output ---\n%s",
			label, result.Code, err, script, result.Output)
	}
	return result.Output
}

// retried is must for the steps that download: the archive is reached over the
// network, so a failed attempt is retried a few times before the test fails.
func (c *container) retried(label, script string) string {
	c.t.Helper()
	result, err := common.Retry(3, 10*time.Second, c.t.Logf, func() (common.Result, error) {
		return c.run(script)
	})
	if err != nil || !result.OK() {
		c.t.Fatalf("%s failed after retries (exit %d, error %v)\n--- script ---\n%s\n--- output ---\n%s",
			label, result.Code, err, script, result.Output)
	}
	return result.Output
}
