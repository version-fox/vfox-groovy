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
local plugin = test.load({ os = "linux", arch = "amd64" })

local function value(entries, key)
    for _, entry in ipairs(entries) do
        if entry.key == key then
            return entry.value
        end
    end
    return nil
end

-- Linux and macOS: forward slashes.
local keys = plugin:EnvKeys({ path = "/home/u/.vfox/sdks/groovy" })
assert(
    value(keys, "GROOVY_HOME") == "/home/u/.vfox/sdks/groovy",
    "GROOVY_HOME: " .. tostring(value(keys, "GROOVY_HOME"))
)
assert(value(keys, "PATH") == "/home/u/.vfox/sdks/groovy/bin", "PATH: " .. tostring(value(keys, "PATH")))

-- The main SDK may come as ctx.main, which vfox versions newer than the ctx.path
-- one pass.
keys = plugin:EnvKeys({ main = { path = "/opt/groovy-4.0.22" } })
assert(value(keys, "GROOVY_HOME") == "/opt/groovy-4.0.22", "main GROOVY_HOME: " .. tostring(value(keys, "GROOVY_HOME")))
assert(value(keys, "PATH") == "/opt/groovy-4.0.22/bin", "main PATH: " .. tostring(value(keys, "PATH")))

-- Windows: backslashes in PATH.
RUNTIME.osType = "windows"
keys = plugin:EnvKeys({ path = "C:\\Users\\u\\.vfox\\sdks\\groovy" })
assert(
    value(keys, "PATH") == "C:\\Users\\u\\.vfox\\sdks\\groovy\\bin",
    "Windows PATH: " .. tostring(value(keys, "PATH"))
)
RUNTIME.osType = "linux"

print("PASS: GROOVY_HOME and PATH on Linux and Windows")
