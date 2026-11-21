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

local http = require("http")
local util = require("util")

--- Fetches the SHA-256 digest Apache publishes beside an SDK zip. A release that
--- publishes none, such as 2.4.5-incubating, answers 404: the result is nil, and
--- vfox says the download is not verified. Any other failure stops the install,
--- so that a download is never installed unchecked because its digest could not
--- be read.
--- @param url string
--- @return string|nil The digest (nil when the release publishes none)
local function fetch_sha256(url)
    local resp, err = http.get({
        url = url,
    })
    if err ~= nil then
        error("Cannot verify the download: failed to fetch " .. url .. ": " .. err)
    end
    if resp.status_code == 404 then
        return nil
    end
    if resp.status_code ~= 200 then
        error("Cannot verify the download: failed to fetch " .. url .. ": status_code => " .. resp.status_code)
    end
    local digest, reason = util.parse_checksum(resp.body)
    if not digest then
        error("Cannot verify the download: " .. url .. " has " .. reason)
    end
    return digest
end

--- @class PreInstallContext
--- @field version string User-input version

--- Returns the SDK zip of one Groovy version, with its SHA-256 digest when
--- Apache publishes one. vfox checks the download against the digest.
--- @param ctx PreInstallContext
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local version = ctx.version
    if not util.valid_version(version) then
        error(
            ("Invalid Groovy version %q: use a version that vfox search groovy lists, such as 4.0.22 or 6.0.0-RC-1"):format(
                tostring(version)
            )
        )
    end

    return {
        version = version,
        url = util.download_url(version),
        sha256 = fetch_sha256(util.checksum_url(version)),
    }
end
