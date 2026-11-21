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
test.load({ os = "linux", arch = "amd64" })
local detect = require("detect_groovy")

-- The environment: the cases set the variables they need, and every other
-- variable reads as unset, so that the machine running the tests does not
-- change the result.
local env = {}
local getenv = os.getenv
os.getenv = function(name)
    return env[name]
end

-- A fake file system. files holds the paths that exist, and dirs maps a folder
-- to the names of its entries. Paths are compared with forward slashes.
local files = {}
local dirs = {}
-- The launchers that may run. On Unix the plugin asks the shell with test -x,
-- which answers yes only for a file that exists and has the execute bit.
local runnable = {}

local function norm(path)
    return (path:gsub("\\", "/"))
end

io.open = function(path, mode)
    if files[norm(path)] then
        return {
            close = function()
                return true
            end,
        }
    end
    return nil
end

-- The handle has read and close and no lines, as vfox's io.popen on Windows
-- gives. A listing is read whole, and a read in any other format fails the test.
io.popen = function(command)
    local launcher = command:match("^test %-x '([^']+)'")
    local output = ""
    if launcher then
        if files[norm(launcher)] and runnable[norm(launcher)] then
            output = "yes\n"
        end
    else
        local dir = command:match("'([^']+)'") or command:match('"([^"]+)"')
        local names = dirs[norm(dir or "")] or {}
        local newline = RUNTIME.osType == "windows" and "\r\n" or "\n"
        for _, name in ipairs(names) do
            output = output .. name .. newline
        end
    end
    return {
        read = function(_, format)
            assert(format == "*a", "the listing is read whole, not with " .. tostring(format))
            return output
        end,
        close = function()
            return true
        end,
    }
end

local function reset()
    for key in pairs(env) do
        env[key] = nil
    end
    for key in pairs(files) do
        files[key] = nil
    end
    for key in pairs(dirs) do
        dirs[key] = nil
    end
    for key in pairs(runnable) do
        runnable[key] = nil
    end
    RUNTIME.osType = "linux"
end

-- Lists the entries of a folder, the way the machine would show them.
local function listing(path, names)
    dirs[norm(path)] = names
end

-- Makes a Groovy SDK at home: its launcher, which can run, and a core jar in
-- folder (lib by default) with the module jars that ship beside it, which do not count.
local function sdk(home, version, launcher, folder, jar)
    local launcher_path = norm(home .. "/bin/" .. (launcher or "groovy"))
    files[launcher_path] = true
    runnable[launcher_path] = true
    local path = norm(home .. "/" .. (folder or "lib"))
    local names = dirs[path] or {}
    table.insert(names, jar or ("groovy-" .. version .. ".jar"))
    table.insert(names, "groovy-json-" .. version .. ".jar")
    dirs[path] = names
end

local cases = 0
local function check(name, want)
    local lines = {}
    for _, entry in ipairs(detect.find_all()) do
        table.insert(lines, entry.version .. "|" .. entry.path .. "|" .. entry.note)
    end
    local got = table.concat(lines, "\n")
    assert(got == want, name .. ":\nexpected:\n" .. want .. "\ngot:\n" .. got)
    cases = cases + 1
end

-- The core jar's version, whatever folder it is in.
assert(detect.version_from_jars({ "/x/lib/groovy-4.0.22.jar", "/x/lib/groovy-4.0.22-indy.jar" }) == "4.0.22")
assert(detect.version_from_jars({ "groovy-json-4.0.22.jar", "groovy-all-2.4.21.jar" }) == nil, "module jars only")
assert(detect.version_from_jars({ "groovy-6.0.0-RC-1.jar" }) == "6.0.0-RC-1", "a pre-release core jar")
cases = cases + 3

-- GROOVY_HOME, a pre-release, with the module jars next to it.
reset()
env.GROOVY_HOME = "/opt/groovy-6.0.0-RC-1"
sdk("/opt/groovy-6.0.0-RC-1", "6.0.0-RC-1")
check("GROOVY_HOME with a pre-release", "6.0.0-RC-1|/opt/groovy-6.0.0-RC-1|pointed to by GROOVY_HOME")

-- The Debian and Ubuntu package keeps its core jar in indy, named with -indy.
reset()
env.HOME = "/home/u"
sdk("/usr/share/groovy", "2.4.21", "groovy", "indy", "groovy-2.4.21-indy.jar")
check("the system package", "2.4.21|/usr/share/groovy|system package")

-- SDKMAN keeps each version in its own folder and current links to one of them:
-- the version is listed once, under the first path in order.
reset()
env.HOME = "/home/u"
listing("/home/u/.sdkman/candidates/groovy", { "4.0.22", "current" })
sdk("/home/u/.sdkman/candidates/groovy/4.0.22", "4.0.22")
sdk("/home/u/.sdkman/candidates/groovy/current", "4.0.22")
check("SDKMAN with current", "4.0.22|/home/u/.sdkman/candidates/groovy/4.0.22|installed by SDKMAN")

-- A folder under a .vfox directory is vfox's own, even when GROOVY_HOME names it.
reset()
env.HOME = "/home/u"
env.GROOVY_HOME = "/home/u/.vfox/sdks/groovy"
sdk("/home/u/.vfox/sdks/groovy", "4.0.22")
check("a vfox-managed home", "")

-- VFOX_HOME may be any folder: an install under it is vfox's own, even when the
-- folder is not called .vfox, and a trailing slash in the variable changes nothing.
reset()
env.HOME = "/home/u"
env.VFOX_HOME = "/data/vfox/"
env.GROOVY_HOME = "/data/vfox/cache/groovy/v-4.0.33/groovy-4.0.33"
sdk("/data/vfox/cache/groovy/v-4.0.33/groovy-4.0.33", "4.0.33")
check("a VFOX_HOME that is not .vfox", "")

-- A folder outside VFOX_HOME is still an SDK.
reset()
env.HOME = "/home/u"
env.VFOX_HOME = "/data/vfox"
env.GROOVY_HOME = "/opt/groovy-4.0.33"
sdk("/opt/groovy-4.0.33", "4.0.33")
check("an SDK outside VFOX_HOME", "4.0.33|/opt/groovy-4.0.33|pointed to by GROOVY_HOME")

-- On Windows the comparison ignores case, and takes backslashes in both paths.
reset()
RUNTIME.osType = "windows"
env.USERPROFILE = "C:\\Users\\u"
env.VFOX_HOME = "D:\\VFox\\"
env.GROOVY_HOME = "D:\\vfox\\cache\\groovy\\v-4.0.33\\groovy-4.0.33"
sdk("D:\\vfox\\cache\\groovy\\v-4.0.33\\groovy-4.0.33", "4.0.33", "groovy.bat")
check("a VFOX_HOME on Windows", "")

-- A core jar without the launcher is not an SDK.
reset()
env.HOME = "/home/u"
sdk("/usr/share/groovy", "2.4.21", "groovy", "indy", "groovy-2.4.21-indy.jar")
files[norm("/usr/share/groovy/bin/groovy")] = nil
check("no launcher", "")

-- A launcher without the execute bit cannot run, so the folder is not offered:
-- vfox would refuse to link it.
reset()
env.HOME = "/home/u"
env.GROOVY_HOME = "/home/u/G"
sdk("/home/u/G", "4.0.33")
runnable[norm("/home/u/G/bin/groovy")] = nil
check("a launcher that is not executable", "")

-- Homebrew keeps the SDK in libexec, behind the opt symlink.
reset()
env.HOME = "/home/u"
sdk("/opt/homebrew/opt/groovy/libexec", "4.0.22")
check("Homebrew", "4.0.22|/opt/homebrew/opt/groovy/libexec|installed by Homebrew")

-- Folders in /opt count only when their names start with groovy.
reset()
env.HOME = "/home/u"
listing("/opt", { "groovy-3.0.25", "tools" })
sdk("/opt/groovy-3.0.25", "3.0.25")
sdk("/opt/tools", "9.9.9")
check("named folders in /opt", "3.0.25|/opt/groovy-3.0.25|installed in /opt")

-- The same version found twice keeps the first path, and the rest are skipped.
reset()
env.HOME = "/home/u"
env.GROOVY_HOME = "/home/u/bin/groovy"
sdk("/home/u/bin/groovy", "4.0.22")
sdk("/usr/share/groovy", "4.0.22")
check("the same version twice", "4.0.22|/home/u/bin/groovy|pointed to by GROOVY_HOME")

-- Several versions come newest first.
reset()
env.HOME = "/home/u"
env.GROOVY_HOME = "/opt/groovy-6.0.0-RC-1"
listing("/home/u/.sdkman/candidates/groovy", { "4.0.22", "6.0.0" })
sdk("/home/u/.sdkman/candidates/groovy/4.0.22", "4.0.22")
sdk("/home/u/.sdkman/candidates/groovy/6.0.0", "6.0.0")
sdk("/opt/groovy-6.0.0-RC-1", "6.0.0-RC-1")
sdk("/usr/share/groovy", "2.4.21", "groovy", "indy", "groovy-2.4.21-indy.jar")
check(
    "newest first",
    table.concat({
        "6.0.0|/home/u/.sdkman/candidates/groovy/6.0.0|installed by SDKMAN",
        "6.0.0-RC-1|/opt/groovy-6.0.0-RC-1|pointed to by GROOVY_HOME",
        "4.0.22|/home/u/.sdkman/candidates/groovy/4.0.22|installed by SDKMAN",
        "2.4.21|/usr/share/groovy|system package",
    }, "\n")
)

-- Windows: Scoop's current folder, with the .bat launcher and backslash paths.
reset()
RUNTIME.osType = "windows"
env.USERPROFILE = "C:\\Users\\u"
env.SystemDrive = "C:"
sdk("C:\\Users\\u\\scoop\\apps\\groovy\\current", "4.0.22", "groovy.bat")
check("Scoop on Windows", "4.0.22|C:\\Users\\u\\scoop\\apps\\groovy\\current|installed by Scoop")

-- Windows: groovy folders in Program Files, and the root of the system drive.
reset()
RUNTIME.osType = "windows"
env.USERPROFILE = "C:\\Users\\u"
env.SystemDrive = "C:"
env.ProgramFiles = "C:\\Program Files"
listing("C:\\Program Files", { "groovy-3.0.25", "Java" })
sdk("C:\\Program Files\\groovy-3.0.25", "3.0.25", "groovy.bat")
sdk("C:\\Program Files\\Java", "21.0.1", "groovy.bat")
listing("C:\\", { "groovy-2.5.23", "Users" })
sdk("C:\\groovy-2.5.23", "2.5.23", "groovy.bat")
check(
    "Windows folders",
    table.concat({
        "3.0.25|C:\\Program Files\\groovy-3.0.25|installed in Program Files",
        "2.5.23|C:\\groovy-2.5.23|installed in the root of the system drive",
    }, "\n")
)

-- Nothing on the machine: no error, no entries.
reset()
env.HOME = "/home/u"
check("nothing installed", "")

RUNTIME.osType = "linux"
os.getenv = getenv
print("PASS: " .. cases .. " SDK detection cases")
