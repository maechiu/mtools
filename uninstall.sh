#!/bin/bash
set -e

SHELL_RC="$HOME/.bashrc"

# ── カラー定義 ────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── ツール定義 ────────────────────────────────
TOOLS=(
  "Rust & Cargo"
  "cargo-binstall"
  "ripgrep (rg)"
  "fd-find (fd)"
  "git-delta (delta)"
  "starship"
  "zellij"
  "direnv"
  "Bun"
  "anyenv"
)

# 選択状態 (0=未選択, 1=選択済み)
SELECTED=(0 0 0 0 0 0 0 0 0 0)

# ── メニュー描画 ──────────────────────────────
# 引数: カーソル位置
draw_menu() {
  local cursor=$1
  tput clear
  echo -e "${BOLD}============================================${RESET}"
  echo -e "${BOLD}      mtools アンインストーラー             ${RESET}"
  echo -e "${BOLD}============================================${RESET}"
  echo ""
  echo -e "  ${CYAN}↑↓${RESET}: 移動  ${CYAN}Space${RESET}: 選択/解除  ${GREEN}Enter${RESET}: 実行"
  echo -e "  ${CYAN}a${RESET}: 全選択  ${CYAN}n${RESET}: 全解除  ${CYAN}q${RESET}: キャンセル"
  echo ""
  for i in "${!TOOLS[@]}"; do
    local checkbox
    if [[ "${SELECTED[$i]}" -eq 1 ]]; then
      checkbox="${GREEN}[x]${RESET}"
    else
      checkbox="[ ]"
    fi
    if [[ "$i" -eq "$cursor" ]]; then
      echo -e "  ${BOLD}${CYAN}▶${RESET} ${checkbox} ${BOLD}${TOOLS[$i]}${RESET}"
    else
      echo -e "    ${checkbox} ${TOOLS[$i]}"
    fi
  done
  echo ""
}

# ── 1文字読み込み (エスケープシーケンス対応) ──
read_key() {
  local key
  IFS= read -rsn1 key
  # エスケープシーケンスの場合は続きを読む
  if [[ "$key" == $'\x1b' ]]; then
    local seq1 seq2
    IFS= read -rsn1 -t 0.1 seq1 || true
    IFS= read -rsn1 -t 0.1 seq2 || true
    key="${key}${seq1}${seq2}"
  fi
  printf '%s' "$key"
}

# ── 対話型選択ループ ──────────────────────────
select_tools() {
  local cursor=0
  local total=${#TOOLS[@]}

  # 終了時にターミナルを確実に元に戻す
  trap 'tput cnorm; tput sgr0' EXIT
  tput civis  # カーソル非表示

  while true; do
    draw_menu "$cursor"

    local key
    key=$(read_key)

    case "$key" in
      # 上矢印
      $'\x1b[A')
        cursor=$(( (cursor - 1 + total) % total ))
        ;;
      # 下矢印
      $'\x1b[B')
        cursor=$(( (cursor + 1) % total ))
        ;;
      # スペース: 選択トグル
      ' ')
        if [[ "${SELECTED[$cursor]}" -eq 1 ]]; then
          SELECTED[$cursor]=0
        else
          SELECTED[$cursor]=1
        fi
        ;;
      # Enter: 決定
      '' | $'\n' | $'\r')
        local any_selected=0
        for s in "${SELECTED[@]}"; do
          [[ "$s" -eq 1 ]] && any_selected=1 && break
        done
        tput cnorm  # カーソル表示に戻す
        if [[ "$any_selected" -eq 0 ]]; then
          tput clear
          echo -e "${YELLOW}何も選択されていません。キャンセルします。${RESET}"
          exit 0
        fi
        break
        ;;
      # 全選択
      'a' | 'A')
        for i in "${!SELECTED[@]}"; do SELECTED[$i]=1; done
        ;;
      # 全解除
      'n' | 'N')
        for i in "${!SELECTED[@]}"; do SELECTED[$i]=0; done
        ;;
      # キャンセル
      'q' | 'Q')
        tput cnorm
        tput clear
        echo "キャンセルしました。"
        exit 0
        ;;
    esac
  done
}

# ── .bashrc からパターンを削除 ────────────────
remove_bashrc_line() {
  local pattern="$1"
  if grep -q "$pattern" "$SHELL_RC" 2>/dev/null; then
    sed -i "\|$pattern|d" "$SHELL_RC"
    echo -e "  ${CYAN}~/.bashrc から削除:${RESET} $pattern"
  fi
}

# ── アンインストール関数群 ────────────────────

uninstall_rust() {
  echo -e "\n${BOLD}[Rust & Cargo] アンインストール中...${RESET}"
  if command -v rustup &>/dev/null; then
    rustup self uninstall -y
    echo -e "  ${GREEN}完了${RESET}"
  else
    echo -e "  ${YELLOW}rustup が見つかりません。スキップします。${RESET}"
  fi
  remove_bashrc_line '\.cargo/env'
}

uninstall_cargo_binstall() {
  echo -e "\n${BOLD}[cargo-binstall] アンインストール中...${RESET}"
  if command -v cargo &>/dev/null && cargo install --list 2>/dev/null | grep -q "cargo-binstall"; then
    cargo uninstall cargo-binstall
    echo -e "  ${GREEN}完了${RESET}"
  else
    echo -e "  ${YELLOW}cargo-binstall が見つかりません。スキップします。${RESET}"
  fi
}

uninstall_ripgrep() {
  echo -e "\n${BOLD}[ripgrep] アンインストール中...${RESET}"
  if command -v rg &>/dev/null; then
    cargo uninstall ripgrep
    echo -e "  ${GREEN}完了${RESET}"
  else
    echo -e "  ${YELLOW}ripgrep が見つかりません。スキップします。${RESET}"
  fi
}

uninstall_fd() {
  echo -e "\n${BOLD}[fd-find] アンインストール中...${RESET}"
  if command -v fd &>/dev/null; then
    cargo uninstall fd-find
    echo -e "  ${GREEN}完了${RESET}"
  else
    echo -e "  ${YELLOW}fd-find が見つかりません。スキップします。${RESET}"
  fi
}

uninstall_delta() {
  echo -e "\n${BOLD}[git-delta] アンインストール中...${RESET}"
  if command -v delta &>/dev/null; then
    cargo uninstall git-delta
    echo -e "  ${GREEN}完了${RESET}"
  else
    echo -e "  ${YELLOW}git-delta が見つかりません。スキップします。${RESET}"
  fi
}

uninstall_starship() {
  echo -e "\n${BOLD}[starship] アンインストール中...${RESET}"
  if command -v starship &>/dev/null; then
    cargo uninstall starship
    echo -e "  ${GREEN}完了${RESET}"
  else
    echo -e "  ${YELLOW}starship が見つかりません。スキップします。${RESET}"
  fi
  remove_bashrc_line 'starship init'
}

uninstall_zellij() {
  echo -e "\n${BOLD}[zellij] アンインストール中...${RESET}"
  if command -v zellij &>/dev/null; then
    cargo uninstall zellij
    echo -e "  ${GREEN}完了${RESET}"
  else
    echo -e "  ${YELLOW}zellij が見つかりません。スキップします。${RESET}"
  fi
}

uninstall_direnv() {
  echo -e "\n${BOLD}[direnv] アンインストール中...${RESET}"
  if command -v direnv &>/dev/null; then
    sudo apt-get remove -y direnv
    echo -e "  ${GREEN}完了${RESET}"
  else
    echo -e "  ${YELLOW}direnv が見つかりません。スキップします。${RESET}"
  fi
  remove_bashrc_line 'direnv hook'
}

uninstall_bun() {
  echo -e "\n${BOLD}[Bun] アンインストール中...${RESET}"
  if [[ -d "$HOME/.bun" ]]; then
    rm -rf "$HOME/.bun"
    echo -e "  ${GREEN}~/.bun を削除しました${RESET}"
  else
    echo -e "  ${YELLOW}~/.bun が見つかりません。スキップします。${RESET}"
  fi
  remove_bashrc_line 'BUN_INSTALL'
  remove_bashrc_line 'bun'
}

uninstall_anyenv() {
  echo -e "\n${BOLD}[anyenv] アンインストール中...${RESET}"
  if [[ -d "$HOME/.anyenv" ]]; then
    rm -rf "$HOME/.anyenv"
    echo -e "  ${GREEN}~/.anyenv を削除しました${RESET}"
  else
    echo -e "  ${YELLOW}~/.anyenv が見つかりません。スキップします。${RESET}"
  fi
  remove_bashrc_line 'anyenv'
}

# ── 確認プロンプト ────────────────────────────
confirm() {
  echo ""
  echo -e "${BOLD}以下のツールをアンインストールします:${RESET}"
  for i in "${!TOOLS[@]}"; do
    [[ "${SELECTED[$i]}" -eq 1 ]] && echo -e "  ${RED}✗ ${TOOLS[$i]}${RESET}"
  done
  echo ""
  echo -n "本当に実行しますか? [y/N]: "
  read -r ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "キャンセルしました。"; exit 0; }
}

# ── メイン処理 ────────────────────────────────
select_tools
confirm

echo ""
echo -e "${BOLD}アンインストールを開始します...${RESET}"

# Rust 系を先にアンインストールする場合、cargo が必要なツールを先に処理
# cargo-binstall → ripgrep → fd → delta → starship → (後で Rust 本体)

[[ "${SELECTED[1]}" -eq 1 ]] && uninstall_cargo_binstall
[[ "${SELECTED[2]}" -eq 1 ]] && uninstall_ripgrep
[[ "${SELECTED[3]}" -eq 1 ]] && uninstall_fd
[[ "${SELECTED[4]}" -eq 1 ]] && uninstall_delta
[[ "${SELECTED[5]}" -eq 1 ]] && uninstall_starship
[[ "${SELECTED[6]}" -eq 1 ]] && uninstall_zellij
[[ "${SELECTED[7]}" -eq 1 ]] && uninstall_direnv
[[ "${SELECTED[8]}" -eq 1 ]] && uninstall_bun
[[ "${SELECTED[9]}" -eq 1 ]] && uninstall_anyenv
# Rust は最後 (他の cargo ツール削除後)
[[ "${SELECTED[0]}" -eq 1 ]] && uninstall_rust

echo ""
echo -e "${GREEN}${BOLD}アンインストール完了！${RESET}"
echo -e "設定を反映するには: ${CYAN}source ~/.bashrc${RESET}"
