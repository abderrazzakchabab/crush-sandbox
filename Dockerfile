# syntax=docker/dockerfile:1

# Crush releases are versioned. Keep this in sync with the release you want;
# install.sh reads this default so both stay aligned.
ARG CRUSH_VERSION=0.100.0
ARG USER_UID=1000
ARG USER_GID=1000

FROM debian:bookworm-slim

ARG CRUSH_VERSION
ARG TARGETARCH
ARG USER_UID
ARG USER_GID

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/crush \
    TERM=xterm-256color

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        less \
        openssh-client \
        procps \
        ripgrep \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN set -eux; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$arch" in \
        amd64) crush_arch=x86_64 ;; \
        arm64) crush_arch=arm64 ;; \
        arm)   crush_arch=armv7 ;; \
        386)   crush_arch=i386 ;; \
        *) echo "unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    base="https://github.com/charmbracelet/crush/releases/download/v${CRUSH_VERSION}"; \
    asset="crush_${CRUSH_VERSION}_Linux_${crush_arch}.tar.gz"; \
    curl -fsSLo "$asset" "$base/$asset"; \
    curl -fsSLo checksums.txt "$base/checksums.txt"; \
    grep "  ${asset}$" checksums.txt | sha256sum -c -; \
    tar -xzf "$asset"; \
    install -Dm0755 "crush_${CRUSH_VERSION}_Linux_${crush_arch}/crush" /usr/local/bin/crush; \
    rm -rf "$asset" checksums.txt "crush_${CRUSH_VERSION}_Linux_${crush_arch}"

# Run as the host user so files created in the bind-mounted workspace keep the
# right ownership. Only create the user/group when the IDs are still free.
RUN set -eux; \
    if ! getent group "$USER_GID" >/dev/null; then \
        groupadd -g "$USER_GID" crush; \
    fi; \
    if ! getent passwd "$USER_UID" >/dev/null; then \
        useradd -l -m -u "$USER_UID" -g "$USER_GID" -s /bin/bash crush; \
    fi; \
    mkdir -p /home/crush/.config/git /workspace; \
    touch /home/crush/.config/AGENTS.md /home/crush/.gitconfig /home/crush/.config/git/config; \
    chown -R "$USER_UID:$USER_GID" /home/crush

LABEL org.opencontainers.image.title="crush-sandbox" \
      org.opencontainers.image.description="Charm Crush in a disposable Docker sandbox" \
      org.opencontainers.image.source="https://github.com/charmbracelet/crush" \
      io.crush.sandbox.version="${CRUSH_VERSION}" \
      io.crush.sandbox.uid="${USER_UID}"

USER ${USER_UID}:${USER_GID}
WORKDIR /workspace

ENTRYPOINT ["crush"]
