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

// Package e2e is the root of the Go module behind the end-to-end suites.
//
// The suites hold no tests of their own at this level. They are split by
// platform:
//
//   - common: the logic both platforms share (the Groovy releases the suites
//     install, the expectations on vfox's output, the plugin archive);
//   - linux: the Linux suite, run in a disposable Ubuntu container through the
//     docker CLI, from a host with Docker (see docs/e2e.md);
//   - windows: the Windows suite, run natively with pwsh on a Windows host.
//
// The unit tests that need no vfox, no Docker and no network run from this
// directory:
//
//	go test -short ./...
package e2e
