# EtherJack ARM Dev Environment

Runs EtherJack on an emulated ARMv7 (Raspberry Pi Zero W) environment inside Docker using QEMU user-static. Lets you edit scripts on your host and test them instantly without physical hardware.

## Requirements

- Docker
- x86/amd64 host (Linux or Mac with Rosetta)

QEMU ARM support is registered automatically on first run.

## Usage

From the repo root:

```sh
bash dev/run.sh
```

This will:
1. Register QEMU ARM binfmt handlers if not already present
2. Build the `etherjack-dev` Docker image (cached after first build)
3. Drop you into an interactive ARM shell at `/usr/local/EtherJack`

The repo is bind-mounted, so any edits you make on the host are reflected immediately — no rebuild needed.

## Inside the container

```
  ARM dev environment — armv7l

  Interfaces:
  eth0@eth0-peer   UP   ...
  eth0-peer@eth0   UP   ...
  wlan0            UP   ...

  Repo mounted at : /usr/local/EtherJack
  Current EJMODE  : EJMODE=preset
```

### Running EtherJack

```sh
# Edit the mode if needed
nano EtherJack.conf     # set EJMODE=lan | wifi | preset

bash EtherJack.sh
```

### Interface layout

| Interface  | Purpose |
|------------|---------|
| `eth0`     | EtherJack's interface — what the scripts see |
| `eth0-peer`| The veth peer — available if you want to inject traffic manually |
| `wlan0`    | Dummy interface for WIFI mode config and iptables rules |

On real Pi hardware, `eth0` would have live LAN traffic as soon as the device is plugged in. In this environment that traffic is absent — see known limitations below.

### Scripted / non-interactive use

Pass a command as an argument to `run.sh` via Docker directly:

```sh
docker run --rm --platform linux/arm/v7 --privileged --network=none \
  -v "$PWD:/usr/local/EtherJack" \
  etherjack-dev bash -c 'bash EtherJack.sh'
```

## Known limitations

### tshark / tcpdump — live capture does not work

QEMU user-static does not fully emulate `AF_PACKET` socket operations required by libpcap. Both `tshark` and `tcpdump` will fail to open a capture session on `eth0`:

```
setsockopt (PACKET_ADD_MEMBERSHIP): Protocol not available
```

**Impact:** `netfinder.sh` will not collect IP addresses from ARP traffic.  
**Workaround:** Use the BATS test suite (`bash dev/run-tests.sh` or CI) to unit-test capture logic with mocked commands.

### hostapd — will not bind to wlan0

`hostapd` requires a real wireless driver with AP mode support. The dummy `wlan0` interface satisfies everything *except* the actual bind. WIFI mode will run through its full setup (IP configuration, iptables rules, dnsmasq) and then print a hostapd error.

### init is intercepted

EtherJack calls `init 0` on an unrecognised `EJMODE`. Inside the container this would kill the shell. A stub `init` in `/dev-bin` intercepts the call and prints a message instead, so the container stays alive.

## Rebuilding the image

Only needed after changing `dev/Dockerfile` or `dev/entrypoint.sh`:

```sh
docker build --platform linux/arm/v7 -t etherjack-dev -f dev/Dockerfile dev/
```
