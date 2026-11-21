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

local util = require("util")

--- Finds Groovy SDKs that are already on the machine, for `vfox link --detect`.
--- Each result names the version the way `vfox install` names it: the number of
--- the core jar, groovy-<version>.jar, with no suffix.
local detect = {}

--- Reports whether the plugin runs on Windows, where paths use backslashes.
local function is_windows()
    return RUNTIME ~= nil and RUNTIME.osType == "windows"
end

--- Returns the separator of paths on this platform.
local function sep()
    return is_windows() and "\\" or "/"
end

--- Joins two path segments with the platform separator.
--- @param left string
--- @param right string
--- @return string
function detect.join(left, right)
    local last = left:sub(-1)
    if last == "/" or last == "\\" then
        return left .. right
    end
    return left .. sep() .. right
end

--- Joins a base path and segments, or returns nil when there is no base.
local function child(base, ...)
    if base == nil or base == "" then
        return nil
    end
    local result = base
    for _, part in ipairs({ ... }) do
        result = detect.join(result, part)
    end
    return result
end

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function shell_quote(value)
    if is_windows() then
        return '"' .. value .. '"'
    end
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

--- Returns the last segment of a path.
local function basename(path)
    return path:match("([^/\\]+)$") or path
end

--- Reports whether a file can be opened for reading.
local function exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

--- Reports whether a path lies under a .vfox directory. vfox manages those
--- installs itself, so they are never offered for linking.
local function is_vfox_managed(path)
    local lower = path:lower()
    return lower:find("/.vfox/", 1, true) ~= nil or lower:find("\\.vfox\\", 1, true) ~= nil
end

--- Lists the entries of dir as full paths, or {} when dir is missing or cannot
--- be read.
--- @param dir string|nil
--- @return string[]
function detect.list_entries(dir)
    if dir == nil or dir == "" then
        return {}
    end
    local command
    if is_windows() then
        command = "dir /b " .. shell_quote(dir) .. " 2>nul"
    else
        command = "ls -1 " .. shell_quote(dir) .. " 2>/dev/null"
    end
    local handle = io.popen(command, "r")
    if not handle then
        return {}
    end
    -- The listing is read whole and split here. vfox's io.popen on Windows
    -- returns a handle with read and close only, and no lines method.
    local output = handle:read("*a") or ""
    handle:close()
    local entries = {}
    for line in output:gmatch("[^\r\n]+") do
        line = trim(line)
        if line ~= "" and line ~= "." and line ~= ".." then
            table.insert(entries, detect.join(dir, line))
        end
    end
    return entries
end

--- Returns the version of the core jar among the names of a lib or indy folder,
--- or nil. The core jar is groovy-<version>.jar, or groovy-<version>-indy.jar in
--- the indy folder of Debian and Ubuntu. Module jars such as
--- groovy-json-4.0.22.jar do not count.
--- @param names string[] Entries of the folder, as full paths or names
--- @return string|nil
function detect.version_from_jars(names)
    local best
    for _, name in ipairs(names) do
        local version = basename(name):match("^groovy%-(%d[^/\\]*)%.jar$")
        if version then
            version = version:gsub("%-indy$", "")
            if best == nil or #version < #best then
                best = version
            end
        end
    end
    return best
end

--- Reports whether a launcher can run. On Windows a .bat file runs by its name,
--- so it only has to exist. On Unix the file must have the execute bit for the
--- user, the same test vfox makes before it links a folder: a launcher without
--- it is not offered, since vfox would refuse to link it.
--- @param path string
--- @return boolean
local function is_runnable(path)
    if is_windows() then
        return exists(path)
    end
    local handle = io.popen("test -x " .. shell_quote(path) .. " && echo yes", "r")
    if not handle then
        return false
    end
    local output = handle:read("*a") or ""
    handle:close()
    return output:find("yes", 1, true) ~= nil
end

--- Reports whether home has the launcher script of a Groovy SDK that can run.
local function has_launcher(home)
    local name = is_windows() and "groovy.bat" or "groovy"
    return is_runnable(detect.join(detect.join(home, "bin"), name))
end

--- Returns the version of the Groovy SDK at home, or nil when home is not one.
--- The core jar is looked for in lib, where SDK zips and Homebrew keep it, and
--- in indy, where the Debian and Ubuntu packages keep it.
--- @param home string
--- @return string|nil
local function version_of_home(home)
    if not has_launcher(home) then
        return nil
    end
    for _, folder in ipairs({ "lib", "indy" }) do
        local version = detect.version_from_jars(detect.list_entries(detect.join(home, folder)))
        if version then
            return version
        end
    end
    return nil
end

--- Returns the places to look for Groovy SDKs on this platform, each with the
--- note `vfox link --detect` shows. The mode says how to read a place: "home"
--- when it is an SDK itself, "children" when each of its entries may be one,
--- and "named" when only the entries whose names start with groovy may be.
--- @return table[]
function detect.candidate_roots()
    local roots = {}
    local function add(path, note, mode)
        if path ~= nil and path ~= "" then
            table.insert(roots, { path = path, note = note, mode = mode })
        end
    end

    add(os.getenv("GROOVY_HOME"), "pointed to by GROOVY_HOME", "home")
    if is_windows() then
        local userprofile = os.getenv("USERPROFILE") or ""
        local drive = os.getenv("SystemDrive") or "C:"
        local programfiles = os.getenv("ProgramFiles") or drive .. "\\Program Files"
        local programdata = os.getenv("ProgramData") or drive .. "\\ProgramData"
        add(child(userprofile, "scoop", "apps", "groovy", "current"), "installed by Scoop", "home")
        add(child(userprofile, ".sdkman", "candidates", "groovy"), "installed by SDKMAN", "children")
        add(child(programdata, "chocolatey", "lib", "groovy", "tools"), "installed by Chocolatey", "children")
        add(programfiles, "installed in Program Files", "named")
        add(drive .. "\\", "installed in the root of the system drive", "named")
    else
        local home = os.getenv("HOME") or ""
        add(child(home, ".sdkman", "candidates", "groovy"), "installed by SDKMAN", "children")
        add(child(home, ".asdf", "installs", "groovy"), "installed by asdf", "children")
        add(child(home, ".local", "share", "mise", "installs", "groovy"), "installed by mise", "children")
        add("/opt/homebrew/opt/groovy/libexec", "installed by Homebrew", "home")
        add("/usr/local/opt/groovy/libexec", "installed by Homebrew", "home")
        add(child(home, ".linuxbrew", "opt", "groovy", "libexec"), "installed by Homebrew", "home")
        add("/home/linuxbrew/.linuxbrew/opt/groovy/libexec", "installed by Homebrew", "home")
        add("/usr/share/groovy", "system package", "home")
        add("/usr/local", "installed in /usr/local", "named")
        add("/opt", "installed in /opt", "named")
    end
    return roots
end

--- Returns the directories under a place that may be Groovy SDKs.
--- @param root table One entry of candidate_roots
--- @return string[]
local function homes_under(root)
    if root.mode == "home" then
        return { root.path }
    end
    local homes = {}
    for _, entry in ipairs(detect.list_entries(root.path)) do
        if root.mode == "children" or basename(entry):lower():find("^groovy") then
            table.insert(homes, entry)
        end
    end
    return homes
end

--- Finds every Groovy SDK on the machine that vfox did not install. The results
--- are sorted newest first, then by path, with one entry per version, since
--- vfox links the first one it sees for a version and skips the rest.
--- @return table[] Entries with version, path and note
function detect.find_all()
    local found = {}
    local seen = {}
    for _, root in ipairs(detect.candidate_roots()) do
        for _, home in ipairs(homes_under(root)) do
            if not seen[home] and not is_vfox_managed(home) then
                seen[home] = true
                local version = version_of_home(home)
                if version then
                    table.insert(found, {
                        version = version,
                        path = home,
                        note = root.note,
                    })
                end
            end
        end
    end

    table.sort(found, function(a, b)
        local order = util.compare(a.version, b.version)
        if order ~= 0 then
            return order > 0
        end
        return a.path < b.path
    end)

    local result = {}
    local seen_versions = {}
    for _, item in ipairs(found) do
        if not seen_versions[item.version] then
            seen_versions[item.version] = true
            table.insert(result, item)
        end
    end
    return result
end

return detect
