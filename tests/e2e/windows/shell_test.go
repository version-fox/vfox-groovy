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
	"slices"
	"testing"
)

// TestIsolatedEnv checks that a run keeps what it needs from the runner, such
// as PATH and the JDK, and none of what would tie it to the machine: no
// VFOX_HOME, no Groovy home, no vfox session flags, and its own home directory.
func TestIsolatedEnv(t *testing.T) {
	base := []string{
		`PATH=C:\Windows`,
		`JAVA_HOME=C:\hostedtoolcache\jdk`,
		`VFOX_HOME=C:\runner\.vfox`,
		`GROOVY_HOME=C:\groovy`,
		`__VFOX_SHELL=pwsh`,
		`__vfox_pid=42`,
		`USERPROFILE=C:\Users\runner`,
		`HOME=/home/runner`,
	}
	got := isolatedEnv(base, `C:\Temp\run`)
	want := []string{
		`PATH=C:\Windows`,
		`JAVA_HOME=C:\hostedtoolcache\jdk`,
		`USERPROFILE=C:\Temp\run`,
		`HOME=C:\Temp\run`,
	}
	if !slices.Equal(got, want) {
		t.Fatalf("isolatedEnv:\n got %q\nwant %q", got, want)
	}
}

// TestEncode checks the argument -EncodedCommand reads: the script as UTF-16LE,
// in base64. The letter A is the two bytes 41 00.
func TestEncode(t *testing.T) {
	if got := encode("A"); got != "QQA=" {
		t.Fatalf("encode(%q) = %q, want %q", "A", got, "QQA=")
	}
}
