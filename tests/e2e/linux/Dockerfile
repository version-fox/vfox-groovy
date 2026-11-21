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

# The image the Linux suite runs every version in. It holds what a user of the
# plugin has to bring: a JDK for Groovy, and vfox. It also holds the Debian
# groovy package, which is the system SDK `vfox link --detect groovy` finds.
# The plugin itself is not in the image; the suite adds it per run, from the
# zip it builds out of the repository.
#
# The build context is this directory. The build runs with the classic
# builder (tests/e2e/linux drives `docker build`), so the RUN steps avoid
# BuildKit-only syntax.

FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

# VFOX_ARCH is the architecture of the vfox release archive: x86_64 or
# aarch64. Each archive is pinned by its SHA-256 from the release's
# checksums.txt, and the version is the one the workflows pin.
ARG VFOX_ARCH=x86_64
ARG VFOX_VERSION=1.1.0

RUN set -o errexit -o nounset -o xtrace; \
    apt-get update; \
    apt-get install --assume-yes --no-install-recommends \
        ca-certificates \
        curl \
        groovy \
        openjdk-21-jdk-headless \
        unzip; \
    rm --recursive --force /var/lib/apt/lists/*; \
    ln --symbolic --force "/usr/lib/jvm/java-21-openjdk-$(dpkg --print-architecture)" /usr/lib/jvm/default-java

# The Debian groovy launcher reads JAVA_HOME from /usr/lib/jvm/default-java,
# which the link above makes the JDK 21 of this image.
ENV JAVA_HOME=/usr/lib/jvm/default-java

RUN set -o errexit -o nounset -o xtrace; \
    case "${VFOX_ARCH}" in \
        x86_64) sha256=3b33c3c468b27bc17aecf0d6d3af24fe49fe204972984904a136a47b402a0ee4 ;; \
        aarch64) sha256=e702e057dfe588200727dfb3cf786d181b13f015cbcc9e13679a3edcfd07e430 ;; \
        *) echo "unsupported VFOX_ARCH ${VFOX_ARCH}" >&2; exit 1 ;; \
    esac; \
    curl --fail --silent --show-error --location --output /tmp/vfox.tar.gz \
        "https://github.com/version-fox/vfox/releases/download/v${VFOX_VERSION}/vfox_${VFOX_VERSION}_linux_${VFOX_ARCH}.tar.gz"; \
    echo "${sha256}  /tmp/vfox.tar.gz" | sha256sum --check; \
    tar --extract --gzip --file /tmp/vfox.tar.gz --directory /usr/local/bin --strip-components=1 \
        "vfox_${VFOX_VERSION}_linux_${VFOX_ARCH}/vfox"; \
    rm --force /tmp/vfox.tar.gz; \
    vfox --version; \
    groovy --version

CMD ["sleep", "infinity"]
