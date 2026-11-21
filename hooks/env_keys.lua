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

--- Each SDK may have different environment variable configurations. Groovy needs
--- GROOVY_HOME and its bin folder on PATH. The SDK path comes as ctx.path, or as
--- ctx.main.path in the vfox versions that pass the main SDK that way. An empty
--- ctx.path counts as missing: an empty string is still true in Lua.
--- @param ctx table Context information
--- @return table[] Environment variables to set
function PLUGIN:EnvKeys(ctx)
    local path = ctx.path
    if path == nil or path == "" then
        path = ctx.main and ctx.main.path or ""
    end
    local separator = RUNTIME.osType == "windows" and "\\" or "/"
    return {
        {
            key = "GROOVY_HOME",
            value = path,
        },
        {
            key = "PATH",
            value = path .. separator .. "bin",
        },
    }
end
