#!/bin/bash
set -e

echo "Installing Rust & Cargo..."

if command -v cargo &>/dev/null; then
  echo "cargo already installed: $(cargo --version)"
  exit 0
fi

curl -fsSL https://sh.rustup.rs | sh -s -- -y

source "$HOME/.cargo/env"

echo "Done: $(cargo --version)"
