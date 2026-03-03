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
  starship \
  zellij

# ── direnv ────────────────────────────────────
if ! command -v direnv &>/dev/null; then
  echo "Installing direnv..."
  sudo apt-get install -y direnv
fi

# ── Bun ───────────────────────────────────────
if ! command -v bun &>/dev/null; then
  echo "Installing bun..."
  curl -fsSL https://bun.sh/install | bash
fi

echo "bun: $(bun --version)"

# ── anyenv ───────────────────────────────────
if [ ! -d "$HOME/.anyenv" ]; then
  echo "Installing anyenv..."
  git clone https://github.com/anyenv/anyenv ~/.anyenv
  ~/.anyenv/bin/anyenv install --init
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

if ! grep -q "anyenv init" "$SHELL_RC"; then
  echo 'export PATH="$HOME/.anyenv/bin:$PATH"' >> "$SHELL_RC"
  echo 'eval "$(anyenv init -)"' >> "$SHELL_RC"
  echo "Added anyenv to $SHELL_RC"
fi

echo "Done! Run: source ~/.bashrc"
