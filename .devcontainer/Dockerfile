# Copyright 2026 Han Li and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The repository dev container (see docs/development.md). It is a Linux
# userland that is the same on every host: the Go toolchain the E2E suites
# need, the Lua and license tooling the lint and license workflows pin, the
# vfox release that runs the hook tests, and the Docker CLI, which drives the
# host daemon through the socket devcontainer.json mounts.
#
# Keep the versions below in step with .github/workflows/ (stylua-action and
# the mise line of lint.yml, the vfox pins of test.yml and e2e.yml, and
# actionlint) and with tests/e2e/linux/Dockerfile (vfox).

FROM golang:1.27.1

# Docker CLI only: the suites drive the host daemon through it.
COPY --from=docker:29-cli /usr/local/bin/docker /usr/local/bin/docker

ARG STYLUA_VERSION=2.5.2
ARG LUA_LANGUAGE_SERVER_VERSION=3.19.1
ARG VFOX_VERSION=1.1.0
ARG ACTIONLINT_VERSION=1.7.7

# The archives are pinned by their SHA-256; each step checks its download
# before it runs anything from it.
RUN <<EOT
set -o errexit -o nounset -o xtrace
apt-get update
apt-get install --assume-yes --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    zip
rm --recursive --force /var/lib/apt/lists/*
case "$(dpkg --print-architecture)" in
    amd64)
        stylua_sha256=bcb0d855e91f102f28a370e850f8566b3b44b79e6274d806ea5246837c0fd5ab
        stylua_asset=stylua-linux-x86_64.zip
        luals_sha256=e9235d2d72ef55bc41cf8c99cda2ed64777682024b4bb81f5dea425060c5cbb8
        luals_asset="lua-language-server-${LUA_LANGUAGE_SERVER_VERSION}-linux-x64.tar.gz"
        vfox_sha256=3b33c3c468b27bc17aecf0d6d3af24fe49fe204972984904a136a47b402a0ee4
        vfox_dir="vfox_${VFOX_VERSION}_linux_x86_64"
        ;;
    arm64)
        stylua_sha256=0ef2ebf0b7e5a652b65c4cb96c6d9ffb3981a98547de3c764465bbf54a8d761a
        stylua_asset=stylua-linux-aarch64.zip
        luals_sha256=abd2572e8fc929dc838a81ffb8473c5bce0bf39bfe8edb4b120b3b623176ce83
        luals_asset="lua-language-server-${LUA_LANGUAGE_SERVER_VERSION}-linux-arm64.tar.gz"
        vfox_sha256=e702e057dfe588200727dfb3cf786d181b13f015cbcc9e13679a3edcfd07e430
        vfox_dir="vfox_${VFOX_VERSION}_linux_aarch64"
        ;;
    *)
        echo "FAIL unsupported architecture $(dpkg --print-architecture)" >&2
        exit 1
        ;;
esac
curl --fail --silent --show-error --location --output /tmp/stylua.zip \
    "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/${stylua_asset}"
echo "${stylua_sha256}  /tmp/stylua.zip" | sha256sum --check
unzip -q /tmp/stylua.zip -d /usr/local/bin
rm --force /tmp/stylua.zip
curl --fail --silent --show-error --location --output /tmp/luals.tar.gz \
    "https://github.com/LuaLS/lua-language-server/releases/download/${LUA_LANGUAGE_SERVER_VERSION}/${luals_asset}"
echo "${luals_sha256}  /tmp/luals.tar.gz" | sha256sum --check
mkdir --parents /opt/lua-language-server
tar --extract --gzip --file /tmp/luals.tar.gz --directory /opt/lua-language-server
rm --force /tmp/luals.tar.gz
ln --symbolic /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
curl --fail --silent --show-error --location --output /tmp/vfox.tar.gz \
    "https://github.com/version-fox/vfox/releases/download/v${VFOX_VERSION}/${vfox_dir}.tar.gz"
echo "${vfox_sha256}  /tmp/vfox.tar.gz" | sha256sum --check
tar --extract --gzip --file /tmp/vfox.tar.gz --directory /usr/local/bin --strip-components=1 "${vfox_dir}/vfox"
rm --force /tmp/vfox.tar.gz
stylua --version
lua-language-server --version
vfox --version
EOT

# The Go tools, at the versions the workflows pin: the license header checker
# (SkyWalking Eyes), and actionlint for the workflow files.
RUN <<EOT
set -o errexit -o nounset -o xtrace
GOBIN=/usr/local/bin go install github.com/apache/skywalking-eyes/cmd/license-eye@v0.9.0
GOBIN=/usr/local/bin go install github.com/rhysd/actionlint/cmd/actionlint@v${ACTIONLINT_VERSION}
command -v license-eye actionlint
EOT
