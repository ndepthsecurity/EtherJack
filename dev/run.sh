#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ---------------------------------------------------------------------------
# Ensure QEMU ARM binfmt handlers are registered so Docker can run arm/v7
# images on this x86 host. This is a one-time no-op after first run.
# ---------------------------------------------------------------------------
if ! grep -rq "arm" /proc/sys/fs/binfmt_misc/ 2>/dev/null; then
    echo "[run] Registering QEMU ARM binfmt handlers..."
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
else
    echo "[run] QEMU ARM binfmt already registered."
fi

# ---------------------------------------------------------------------------
# Build the dev image (cached after first build)
# ---------------------------------------------------------------------------
echo "[run] Building ARM dev image..."
docker build \
    --platform linux/arm/v7 \
    -t etherjack-dev \
    -f "$SCRIPT_DIR/Dockerfile" \
    "$SCRIPT_DIR"

# ---------------------------------------------------------------------------
# Launch the container
#   --privileged  needed for ip link / iptables inside the container
#   -v            mount the live repo so edits on the host take effect
#                 immediately — no rebuild required
# ---------------------------------------------------------------------------
echo "[run] Launching EtherJack ARM dev environment..."
docker run --rm -it \
    --platform linux/arm/v7 \
    --privileged \
    --network=none \
    -v "$REPO_ROOT:/usr/local/EtherJack" \
    etherjack-dev
