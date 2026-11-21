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
	"encoding/base64"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
	"unicode/utf16"

	"github.com/version-fox/vfox-groovy/tests/e2e/common"
)

// shell runs PowerShell scripts for one version, with a home directory of its
// own, so that no run sees another run's installs.
type shell struct {
	t    *testing.T
	home string
}

// encode turns a script into the argument -EncodedCommand reads: the UTF-16LE
// bytes of the script in base64. Passing it this way spares the script the
// quoting of the command line.
func encode(script string) string {
	units := utf16.Encode([]rune(script))
	buf := make([]byte, 0, 2*len(units))
	for _, unit := range units {
		buf = append(buf, byte(unit), byte(unit>>8))
	}
	return base64.StdEncoding.EncodeToString(buf)
}

// quote renders s as a PowerShell single-quoted string literal.
func quote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", "''") + "'"
}

// dropped names the variables a run does not inherit: vfox's own home, and the
// Groovy home of the machine, which would make a run depend on what is
// installed there. The home directory is set for every run, below.
var dropped = map[string]bool{
	"VFOX_HOME":   true,
	"GROOVY_HOME": true,
	"USERPROFILE": true,
	"HOME":        true,
}

// isolatedEnv returns base as the environment of one run: without the variables
// dropped names, and without vfox's session flags (__VFOX_*), which a shell
// inside a vfox session would pass on. home becomes the home directory, as
// USERPROFILE on Windows and HOME elsewhere, so that vfox keeps its tmp, plugin,
// cache and sdks under home\.vfox, as it does in a user's home.
//
// VFOX_HOME is not set on purpose. vfox creates the plugin and cache folders in
// it with os.Mkdir, which needs VFOX_HOME itself to exist already, so a new
// directory makes `vfox add` fail.
func isolatedEnv(base []string, home string) []string {
	var env []string
	for _, kv := range base {
		name, _, _ := strings.Cut(kv, "=")
		upper := strings.ToUpper(name)
		if dropped[upper] || strings.HasPrefix(upper, "__VFOX_") {
			continue
		}
		env = append(env, kv)
	}
	return append(env, "USERPROFILE="+home, "HOME="+home)
}

// run runs script in a new pwsh and returns its result. A script that exits
// non-zero is a result with its exit code; an error means pwsh could not run.
func (s *shell) run(script string) (common.Result, error) {
	cmd := exec.Command("pwsh", "-NoProfile", "-NonInteractive", "-EncodedCommand", encode(script))
	cmd.Env = isolatedEnv(os.Environ(), s.home)
	out, err := cmd.CombinedOutput()
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		return common.Result{Code: exitErr.ExitCode(), Output: string(out)}, nil
	}
	if err != nil {
		return common.Result{}, fmt.Errorf("pwsh: %w", err)
	}
	return common.Result{Output: string(out)}, nil
}

// must runs script under label and fails the test unless it exits 0. It
// returns the output.
func (s *shell) must(label, script string) string {
	s.t.Helper()
	result, err := s.run(script)
	if err != nil || !result.OK() {
		s.t.Fatalf("%s failed (exit %d, error %v)\n--- script ---\n%s\n--- output ---\n%s",
			label, result.Code, err, script, result.Output)
	}
	return result.Output
}

// retried is must for the steps that download. The archive is reached over the
// network, so a failed attempt is retried a few times before the test fails.
func (s *shell) retried(label, script string) string {
	s.t.Helper()
	result, err := common.Retry(3, 10*time.Second, s.t.Logf, func() (common.Result, error) {
		return s.run(script)
	})
	if err != nil || !result.OK() {
		s.t.Fatalf("%s failed after retries (exit %d, error %v)\n--- script ---\n%s\n--- output ---\n%s",
			label, result.Code, err, script, result.Output)
	}
	return result.Output
}
