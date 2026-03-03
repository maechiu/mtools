#!/bin/bash
set -e

# ── Rust & Cargo ──────────────────────────────
if ! command -v cargo &>/dev/null; then
  echo "Installing Rust..."
  curl -fsSL https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
fi

echo "cargo: $(cargo --version)"

# ── cargo-binstall ────────────────────────────
if ! command -v cargo-binstall &>/dev/null; then
  echo "Installing cargo-binstall..."
  curl -L --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-scripts.sh | bash
fi

# ── Rust tools ────────────────────────────────
echo "Installing Rust tools..."
cargo binstall -y \
  ripgrep \
  fd-find \
  git-delta \
  starship

# ── direnv ────────────────────────────────────
if ! command -v direnv &>/dev/null; then
  echo "Installing direnv..."
  sudo apt-get install -y direnv
fi

# ── Shell hooks (.bashrc) ─────────────────────
SHELL_RC="$HOME/.bashrc"

if ! grep -q "starship init" "$SHELL_RC"; then
  echo 'eval "$(starship init bash)"' >> "$SHELL_RC"
  echo "Added starship to $SHELL_RC"
fi

if ! grep -q "direnv hook" "$SHELL_RC"; then
  echo 'eval "$(direnv hook bash)"' >> "$SHELL_RC"
  echo "Added direnv to $SHELL_RC"
fi

echo "Done! Run: source ~/.bashrc"
