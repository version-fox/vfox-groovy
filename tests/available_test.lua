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

-- The top of the Apache archive's index for Groovy, trimmed: the sort links,
-- the parent link, KEYS, geb/ and an anchor without an href are all there.
local INDEX = [[
<html><head><title>Index of /dist/groovy</title></head><body>
<h1>Index of /dist/groovy</h1>
<pre><a href="/dist/">Parent Directory</a>
<a href="?C=N;O=D">Name</a> <a href="?C=M;O=A">Last modified</a>
<a name="no-href">an anchor without href</a>
<a href="2.4.21/">2.4.21/</a>
<a href="2.4.5-incubating/">2.4.5-incubating/</a>
<a href="5.0.0-alpha-2/">5.0.0-alpha-2/</a>
<a href="5.0.0-alpha-10/">5.0.0-alpha-10/</a>
<a href="6.0.0/">6.0.0/</a>
<a href="6.0.0-RC-1/">6.0.0-RC-1/</a>
<a href="KEYS">KEYS</a>
<a href="geb/">geb/</a>
</pre></body></html>
]]

-- What the next request gets back: a response, or a transport error.
local reply = {}
local requests = {}
local plugin = test.load({
    os = "linux",
    arch = "amd64",
    http = function(request)
        table.insert(requests, request.url)
        if reply.error then
            return nil, reply.error
        end
        return reply.response
    end,
})

reply.response = { status_code = 200, body = INDEX }
local versions = plugin:Available({})

assert(#requests == 1, "expected one request, got " .. #requests)
assert(
    requests[1] == "https://archive.apache.org/dist/groovy/",
    "expected the archive index, got " .. tostring(requests[1])
)

local want = {
    { version = "6.0.0", note = "" },
    { version = "6.0.0-RC-1", note = "pre-release" },
    { version = "5.0.0-alpha-10", note = "pre-release" },
    { version = "5.0.0-alpha-2", note = "pre-release" },
    { version = "2.4.21", note = "" },
    { version = "2.4.5-incubating", note = "incubating" },
}
assert(#versions == #want, ("expected %d versions, got %d"):format(#want, #versions))
for i, item in ipairs(want) do
    assert(
        versions[i].version == item.version,
        ("version %d: expected %s, got %s"):format(i, item.version, tostring(versions[i].version))
    )
    assert(
        versions[i].note == item.note,
        ("%s: expected note %q, got %q"):format(item.version, item.note, tostring(versions[i].note))
    )
end

-- A failed index is an error that says why. These cases come last, since
-- pcall would hide the closure's later assignments (see util_test.lua).
reply.response = nil
reply.error = "connection reset"
local ok, err = pcall(plugin.Available, plugin, {})
assert(
    not ok and tostring(err):find("connection reset", 1, true),
    "expected the transport error, got " .. tostring(err)
)

reply.error = nil
reply.response = { status_code = 503, body = "Service Unavailable" }
ok, err = pcall(plugin.Available, plugin, {})
assert(not ok and tostring(err):find("status_code => 503", 1, true), "expected the status, got " .. tostring(err))

print("PASS: available versions and index errors")
