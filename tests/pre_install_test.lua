-- Copyright 2026 Han Li and contributors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local test = require("vfox.test")

local ARCHIVE = "https://archive.apache.org/dist/groovy"
local DIGEST = "17448950dea0280f708c778c43d0d1b41778ba58c5b4128a8ba1e7c0bed75bea"

-- The responses by URL. A URL missing from the table answers 404, as the
-- archive does for a checksum a release does not have.
local files = {}
local requests = {}
local function answer(request)
    table.insert(requests, request.url)
    local file = files[request.url]
    if file == nil then
        return { status_code = 404, body = "Not Found" }
    end
    if file.error then
        return nil, file.error
    end
    return file
end

local plugin = test.load({ os = "linux", arch = "amd64", http = answer })

-- The mirror comes from the environment, which the cases set for each call.
local env = {}
local getenv = os.getenv
os.getenv = function(name)
    if name == "VFOX_GROOVY_MIRROR" then
        return env.mirror
    end
    return getenv(name)
end

local function sdk_url(version, artifact)
    return ("%s/%s/distribution/apache-groovy-sdk-%s.zip"):format(ARCHIVE, version, artifact or version)
end

-- A release with a SHA-256 digest: the zip and the digest are both fetched.
files[sdk_url("4.0.22") .. ".sha256"] = { status_code = 200, body = DIGEST .. "\r\n" }
local result = plugin:PreInstall({ version = "4.0.22" })
assert(result.version == "4.0.22", "version: " .. tostring(result.version))
assert(result.url == sdk_url("4.0.22"), "url: " .. tostring(result.url))
assert(result.sha256 == DIGEST, "sha256: " .. tostring(result.sha256))
assert(requests[#requests] == sdk_url("4.0.22") .. ".sha256", "the digest is fetched from the .sha256 file")

-- An incubator release: its file has no suffix, and it publishes no SHA-256,
-- so the install goes on without a digest.
result = plugin:PreInstall({ version = "2.4.5-incubating" })
assert(result.version == "2.4.5-incubating", "incubator version kept: " .. tostring(result.version))
assert(result.url == sdk_url("2.4.5-incubating", "2.4.5"), "incubator url: " .. tostring(result.url))
assert(result.sha256 == nil, "no digest is expected for 2.4.5-incubating")

-- A release candidate with a digest.
files[sdk_url("6.0.0-RC-1") .. ".sha256"] = { status_code = 200, body = DIGEST }
result = plugin:PreInstall({ version = "6.0.0-RC-1" })
assert(result.url == sdk_url("6.0.0-RC-1"), "release candidate url: " .. tostring(result.url))
assert(result.sha256 == DIGEST, "release candidate sha256: " .. tostring(result.sha256))

-- A checksum that cannot be fetched or read does not fail the install.
files[sdk_url("5.0.0") .. ".sha256"] = { error = "connection reset" }
result = plugin:PreInstall({ version = "5.0.0" })
assert(result.sha256 == nil, "a failed fetch gives no digest")
files[sdk_url("5.0.1") .. ".sha256"] = { status_code = 200, body = "<html>oops</html>" }
result = plugin:PreInstall({ version = "5.0.1" })
assert(result.sha256 == nil, "a page that is not a digest gives no digest")

-- A mirror serves the zip and the digest, and the install uses it.
env.mirror = "https://mirror.example.com/apache/groovy/"
local mirrored = ("%s/4.0.22/distribution/apache-groovy-sdk-4.0.22.zip"):format(
    "https://mirror.example.com/apache/groovy"
)
files[mirrored .. ".sha256"] = { status_code = 200, body = DIGEST }
result = plugin:PreInstall({ version = "4.0.22" })
assert(result.url == mirrored, "mirrored url: " .. tostring(result.url))
assert(result.sha256 == DIGEST, "mirrored digest: " .. tostring(result.sha256))
env.mirror = nil

-- Versions that cannot name an archive directory are refused before any request.
-- These cases come last, since pcall would hide the closure's later assignments
-- (see util_test.lua).
local count = #requests
for _, version in ipairs({ "../4.0.22", "latest", "4..0" }) do
    local ok, err = pcall(plugin.PreInstall, plugin, { version = version })
    assert(not ok and tostring(err):find("Invalid Groovy version", 1, true), version .. ": " .. tostring(err))
end
assert(#requests == count, "an invalid version makes no request")

print("PASS: PreInstall names, verifies and mirrors downloads")
