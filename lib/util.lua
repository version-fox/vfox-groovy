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

local util = {}

--- The Apache archive that keeps every Groovy release. Each version has a
--- directory whose distribution/ folder holds its SDK zip and the zip's
--- .sha256 file.
util.ARCHIVE = "https://archive.apache.org/dist/groovy"

--- Returns the base URL of the archive, without a trailing slash. When
--- VFOX_GROOVY_MIRROR is set, the archive is read from there instead, as long
--- as it keeps the same layout (see docs/mirror.md). A blank value is unset.
--- @return string
function util.archive_url()
    local mirror = os.getenv("VFOX_GROOVY_MIRROR")
    if mirror then
        mirror = mirror:match("^%s*(.-)%s*$")
    end
    if mirror == nil or mirror == "" then
        return util.ARCHIVE
    end
    if not mirror:match("^https?://") then
        error(
            "VFOX_GROOVY_MIRROR must start with http:// or https://, such as https://mirror.example.com/apache/groovy, but is "
                .. mirror
        )
    end
    return (mirror:gsub("/+$", ""))
end

--- Returns the version as Apache names the SDK file. The SDK of 2.4.5-incubating
--- is apache-groovy-sdk-2.4.5.zip inside the 2.4.5-incubating directory.
--- @param version string
--- @return string
function util.artifact_version(version)
    return (version:gsub("%-incubating$", ""))
end

--- Returns the URL of the SDK zip of a version.
--- @param version string
--- @return string
function util.download_url(version)
    return ("%s/%s/distribution/apache-groovy-sdk-%s.zip"):format(
        util.archive_url(),
        version,
        util.artifact_version(version)
    )
end

--- Returns the URL of the SHA-256 digest of the SDK zip of a version.
--- @param version string
--- @return string
function util.checksum_url(version)
    return util.download_url(version) .. ".sha256"
end

--- Reports whether a version can name a release in the archive: a digit first,
--- then letters, digits, dots and dashes, as 4.0.22, 2.4.5-incubating and
--- 6.0.0-RC-1 do. Anything else would change the URL it is put in.
--- @param version any
--- @return boolean
function util.valid_version(version)
    return type(version) == "string" and version:match("^%d[%w%.%-]*$") ~= nil and not version:find("..", 1, true)
end

--- Returns the SHA-256 digest a .sha256 file holds. The file has the digest
--- alone or followed by the file name. Returns nil and the reason otherwise.
--- @param body any
--- @return string|nil
--- @return string|nil
function util.parse_checksum(body)
    local digest = type(body) == "string" and body:match("^%s*(%x+)") or nil
    if digest and #digest == 64 then
        return digest:lower()
    end
    return nil, "no SHA-256 digest in the checksum file"
end

--- Returns the version a line of the archive index names, such as 4.0.22 for
--- "4.0.22/". The other links (sort orders, the parent, KEYS, geb/) give nil.
--- @param href any
--- @return string|nil
function util.version_from_entry(href)
    if type(href) ~= "string" then
        return nil
    end
    return href:match("^(%d[%w%.%-]*)/$")
end

--- Returns what `vfox search` says about a version: pre-release for alpha, beta
--- and release candidates, incubating for the incubator releases, else nothing.
--- @param version string
--- @return string
function util.note(version)
    local lower = version:lower()
    if lower:find("-incubating", 1, true) then
        return "incubating"
    end
    if lower:find("-alpha", 1, true) or lower:find("-beta", 1, true) or lower:find("-rc", 1, true) then
        return "pre-release"
    end
    return ""
end

local STAGE_ALPHA, STAGE_BETA, STAGE_RC, STAGE_RELEASE = 1, 2, 3, 4

--- Splits a version into its release numbers, its stage and its build number.
--- Stages order alpha, beta, release candidate and then the release itself.
--- Incubator releases count as releases.
local function split(version)
    local core, rest = version:match("^(%d[%d%.]*)(.*)$")
    local numbers = {}
    for number in core:gmatch("%d+") do
        table.insert(numbers, tonumber(number))
    end
    local lower = rest:lower()
    local stage = STAGE_RELEASE
    if lower:find("alpha", 1, true) then
        stage = STAGE_ALPHA
    elseif lower:find("beta", 1, true) then
        stage = STAGE_BETA
    elseif lower:find("rc", 1, true) then
        stage = STAGE_RC
    end
    -- tonumber(nil) is an error in Lua 5.1, so the digits are checked first.
    local digits = rest:match("(%d+)%D*$")
    local build = digits and tonumber(digits) or 0
    return numbers, stage, build
end

--- Compares two Groovy versions and returns -1 when a is older, 0 when they are
--- the same and 1 when a is newer. Numbers compare as numbers, so 4.0.10 is
--- newer than 4.0.9, and 6.0.0 is newer than 6.0.0-RC-3, which is newer than
--- 6.0.0-RC-1.
--- @param a string
--- @param b string
--- @return integer
function util.compare(a, b)
    local x, stage_a, build_a = split(a)
    local y, stage_b, build_b = split(b)
    for i = 1, math.max(#x, #y) do
        local p, q = x[i] or 0, y[i] or 0
        if p ~= q then
            return p < q and -1 or 1
        end
    end
    if stage_a ~= stage_b then
        return stage_a < stage_b and -1 or 1
    end
    if build_a ~= build_b then
        return build_a < build_b and -1 or 1
    end
    return 0
end

return util
