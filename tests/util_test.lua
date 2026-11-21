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
test.load()
local util = require("util")

-- The mirror comes from the environment: os.getenv answers for it from this
-- table, whose field the cases set, and for everything else as it did.
local env = {}
local getenv = os.getenv
os.getenv = function(name)
    if name == "VFOX_GROOVY_MIRROR" then
        return env.mirror
    end
    return getenv(name)
end

local cases = 0
local function check(got, want, message)
    assert(got == want, ("%s: expected %s, got %s"):format(message, tostring(want), tostring(got)))
    cases = cases + 1
end

-- Each version is older than the one after it, as the archive's names order
-- them: alpha before beta before RC before the release, numbers as numbers.
local ordered = {
    "2.4.5-incubating",
    "2.4.21",
    "3.0.0-alpha-1",
    "3.0.0-alpha-2",
    "3.0.0-beta-1",
    "3.0.0-rc-1",
    "3.0.0",
    "5.0.0-alpha-2",
    "5.0.0-alpha-10",
    "6.0.0-RC-1",
    "6.0.0-RC-3",
    "6.0.0",
}
for i = 1, #ordered - 1 do
    check(util.compare(ordered[i], ordered[i + 1]), -1, ordered[i] .. " against " .. ordered[i + 1])
    check(util.compare(ordered[i + 1], ordered[i]), 1, ordered[i + 1] .. " against " .. ordered[i])
end
check(util.compare("4.0.22", "4.0.22"), 0, "the same version")
check(util.compare("4.0.10", "4.0.9"), 1, "numbers compare as numbers")

-- Notes: pre-releases and incubator releases say so, releases say nothing.
check(util.note("2.4.5-incubating"), "incubating", "note of an incubator release")
check(util.note("5.0.0-alpha-1"), "pre-release", "note of an alpha")
check(util.note("6.0.0-RC-1"), "pre-release", "note of a release candidate")
check(util.note("4.0.22"), "", "note of a release")

-- Index entries: only the version directories name a version.
check(util.version_from_entry("4.0.22/"), "4.0.22", "a version directory")
check(util.version_from_entry("6.0.0-RC-1/"), "6.0.0-RC-1", "a pre-release directory")
check(util.version_from_entry("2.4.5-incubating/"), "2.4.5-incubating", "an incubator directory")
check(util.version_from_entry("KEYS"), nil, "the KEYS file")
check(util.version_from_entry("geb/"), nil, "a directory that is not a version")
check(util.version_from_entry("?C=N;O=D"), nil, "a sort link")
check(util.version_from_entry("/dist/"), nil, "the parent link")
check(util.version_from_entry("4.0.22/distribution/"), nil, "a file inside a version directory")
check(util.version_from_entry(nil), nil, "an anchor without href")

-- Versions that may go into a URL, and those that may not.
for _, version in ipairs({ "4.0.22", "2.4.5-incubating", "6.0.0-RC-1" }) do
    check(util.valid_version(version), true, version .. " is a version")
end
for _, version in ipairs({ "../4.0.22", "4..0", "latest", "", "4.0.22/x", "v4.0.22" }) do
    check(util.valid_version(version), false, version .. " is not a version")
end
check(util.valid_version(nil), false, "nil is not a version")

-- The SDK file of 2.4.5-incubating has no suffix; the directory keeps it.
check(util.artifact_version("2.4.5-incubating"), "2.4.5", "artifact of an incubator release")
check(util.artifact_version("6.0.0-RC-1"), "6.0.0-RC-1", "artifact of a release candidate")
check(
    util.download_url("2.4.5-incubating"),
    "https://archive.apache.org/dist/groovy/2.4.5-incubating/distribution/apache-groovy-sdk-2.4.5.zip",
    "download URL of an incubator release"
)
check(
    util.download_url("6.0.0-RC-1"),
    "https://archive.apache.org/dist/groovy/6.0.0-RC-1/distribution/apache-groovy-sdk-6.0.0-RC-1.zip",
    "download URL of a release candidate"
)
check(
    util.checksum_url("4.0.22"),
    "https://archive.apache.org/dist/groovy/4.0.22/distribution/apache-groovy-sdk-4.0.22.zip.sha256",
    "checksum URL"
)

-- A checksum file holds the digest alone, or followed by the file name.
local digest = "17448950dea0280f708c778c43d0d1b41778ba58c5b4128a8ba1e7c0bed75bea"
check(util.parse_checksum(digest .. "\r\n"), digest, "digest alone")
check(util.parse_checksum(digest:upper() .. "  apache-groovy-sdk-4.0.22.zip\n"), digest, "digest with a file name")
check(util.parse_checksum("d41d8cd98f00b204e9800998ecf8427e"), nil, "an MD5 is not a SHA-256")
check(util.parse_checksum("<html>Not Found</html>"), nil, "an HTML page is not a digest")
check(util.parse_checksum(nil), nil, "no body")

-- VFOX_GROOVY_MIRROR replaces the archive; a blank value is unset.
env.mirror = nil
check(util.archive_url(), "https://archive.apache.org/dist/groovy", "no mirror")
for _, mirror in ipairs({ "", " ", "\t\n" }) do
    env.mirror = mirror
    check(util.archive_url(), "https://archive.apache.org/dist/groovy", "blank mirror " .. ("%q"):format(mirror))
end
env.mirror = "https://mirror.example.com/apache/groovy/"
check(util.archive_url(), "https://mirror.example.com/apache/groovy", "mirror with a trailing slash")
check(
    util.download_url("4.0.22"),
    "https://mirror.example.com/apache/groovy/4.0.22/distribution/apache-groovy-sdk-4.0.22.zip",
    "download URL through the mirror"
)
env.mirror = " http://127.0.0.1:8080/groovy \n"
check(util.archive_url(), "http://127.0.0.1:8080/groovy", "mirror with blanks around it")

-- A mirror that is not an http or https address is refused, with its value.
-- These cases come last: once pcall has caught an error, gopher-lua's closures
-- no longer see later assignments to the locals around them.
for _, mirror in ipairs({ "mirror.example.com/groovy", "ftp://mirror.example.com/groovy", "HTTPS://mirror.example.com" }) do
    env.mirror = mirror
    local ok, err = pcall(util.archive_url)
    assert(not ok, mirror .. ": expected an error")
    assert(
        tostring(err):find("VFOX_GROOVY_MIRROR must start with http:// or https://", 1, true),
        mirror .. ": unexpected error " .. tostring(err)
    )
    cases = cases + 1
end

print("PASS: " .. cases .. " version, URL and mirror cases")
