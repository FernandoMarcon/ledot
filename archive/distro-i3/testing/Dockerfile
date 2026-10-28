FROM ubuntu:24.04

# ── Build args ────────────────────────────────────────────────────────────────
# Pass --build-arg UID=$(id -u) so the container user owns mounted volumes.
ARG UID=1000
ARG USERNAME=tester

# ── Environment ───────────────────────────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    HOME=/home/${USERNAME}

# ── Base system packages ──────────────────────────────────────────────────────
# This layer stays thin on purpose: it only contains what is needed to
# bootstrap the test environment itself.  The actual rice packages are
# installed module-by-module during the test session.
RUN apt-get update && apt-get install -y --no-install-recommends \
    # X server (virtual framebuffer for VNC mode)
    xvfb \
    xserver-xephyr \
    # VNC server + noVNC web viewer
    x11vnc \
    novnc \
    websockify \
    # minimal terminal so we have something to work with before Alacritty lands
    xterm \
    # privilege escalation (modules call sudo apt-get)
    sudo \
    # utilities used by preflight / modules
    curl \
    wget \
    git \
    ca-certificates \
    iproute2 \
    procps \
    dbus \
    dbus-x11 \
    # text editor for quick edits inside container
    nano \
    # needed by 01_repos (add-apt-repository)
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# ── Create user ───────────────────────────────────────────────────────────────
RUN existing=$(getent passwd "${UID}" | cut -d: -f1 || true); \
    if [ -n "$existing" ] && [ "$existing" != "${USERNAME}" ]; then \
        usermod -l "${USERNAME}" -d "/home/${USERNAME}" -m "$existing"; \
        groupmod -n "${USERNAME}" "$existing" 2>/dev/null || true; \
    elif [ -z "$existing" ]; then \
        useradd -m -u "${UID}" -s /bin/bash "${USERNAME}"; \
    fi && \
    echo "${USERNAME}:${USERNAME}" | chpasswd && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME}

# ── Copy init scripts ─────────────────────────────────────────────────────────
COPY scripts/container-init.sh /usr/local/bin/container-init
RUN chmod +x /usr/local/bin/container-init

# ── Ports ─────────────────────────────────────────────────────────────────────
# 5900 → VNC   6080 → noVNC (browser)
EXPOSE 5900 6080

USER ${USERNAME}
WORKDIR ${HOME}

ENTRYPOINT ["/usr/local/bin/container-init"]
CMD ["bash", "--login"]
