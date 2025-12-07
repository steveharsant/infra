#!/usr/bin/env bash

# shellcheck disable=SC1091

# This installs the latest release of Spotifyd after building it from source.
# Spotifyd prebuilt binaries use OpenSSL 1.1 which is not abailable for Raspberry Pi's OS.
# This script will build the binary with the current OpenSSL 3.1 libs already installed on the system.

# Install dependencies
sudo apt-install -y \
  cmake \
  git \
  libasound2-dev \
  libclang-dev \
  libdbus-1-dev \
  libpulse-dev \
  libssl-dev

# Install Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env" 

cd /tmp || exit 1

# Checkout latest tagged release
git clone --depth 1 --branch "$(git ls-remote --tags https://github.com/Spotifyd/spotifyd.git \
  | awk -F/ '{print $NF}' | grep -v '{}' | sort -V | tail -n1)" \
  https://github.com/Spotifyd/spotifyd.git

cd /tmp/spotifyd || exit 1

# Build binary 
cargo build --release --locked

# Install binary
mv /tmp/spotifyd/target/release/spotifyd /usr/bin/spotifyd
chown root:root /usr/bin/spotifyd
chmod +x /usr/bin/spotifyd
