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
local html = require("html")
local util = require("util")

--- The release index of the Apache archive for Groovy: the page that vfox search
--- groovy lists, and that an install checks a version against.
local archive_index = {}

--- Returns every version the archive index lists, newest first. Pre-releases
--- stay in the list, marked with a note, so that they can be installed as well.
--- An index without any release is an error, not an empty list.
--- @return table[] Descriptions of available versions: version and note
function archive_index.versions()
    local url = util.archive_url() .. "/"
    local resp, err = http.get({
        url = url,
    })
    if err ~= nil then
        error("failed to read the Groovy release index at " .. url .. ": " .. err)
    end
    if resp.status_code ~= 200 then
        error("failed to read the Groovy release index at " .. url .. ": status_code => " .. resp.status_code)
    end

    local versions = {}
    local seen = {}
    html.parse(resp.body):find("a"):each(function(i, selection)
        local version = util.version_from_entry(selection:attr("href"))
        if version and not seen[version] then
            seen[version] = true
            table.insert(versions, {
                version = version,
                note = util.note(version),
            })
        end
    end)
    -- vfox keeps an empty list in its cache and reports no available version,
    -- so an index without any release is an error instead.
    if #versions == 0 then
        error("failed to read the Groovy release index at " .. url .. ": no release is listed")
    end
    table.sort(versions, function(a, b)
        return util.compare(a.version, b.version) > 0
    end)
    return versions
end

--- Reports whether the archive index lists a version, by its exact name.
--- @param version string
--- @return boolean
function archive_index.lists(version)
    for _, item in ipairs(archive_index.versions()) do
        if item.version == version then
            return true
        end
    end
    return false
end

return archive_index
