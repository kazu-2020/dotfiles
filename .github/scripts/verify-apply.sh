#!/usr/bin/env bash
# 使い方: .github/scripts/verify-apply.sh [ソースディレクトリ]
set -euo pipefail

src="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
rc=0

# --destination だけでは永続ステート (~/.config/chezmoi/chezmoistate.boltdb) が $HOME 側のままなので、--persistent-state も渡す
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
dest="$work/dest"
mkdir "$dest"

cm() {
  chezmoi --source "$src" --destination "$dest" \
    --config "$work/chezmoi.toml" --persistent-state "$work/state.boltdb" "$@"
}

ng() {
  echo "NG: $*" >&2
  rc=1
}

# execute-template ではなく init を使うのは、init だけが config テンプレートのハッシュを永続ステートに記録するため。
# 記録が無いと以降の apply / status が「config が古い」と毎回警告する
cm init --promptBool "Do you want to install external casks=true" \
  --promptBool "Is this a work machine=true"

cm apply --exclude scripts
echo "OK: chezmoi apply"

if [ -n "$(find "$dest/.config/zsh/work.zsh" -perm 600 2>/dev/null)" ]; then
  echo "OK: work.zsh が 0600"
else
  ng "work.zsh が 0600 で配置されていない"
fi

st="$(cm status --exclude scripts)"
if [ -z "$st" ]; then
  echo "OK: 2 回目の status が空"
else
  ng "apply 後も status が差分を報告する
$st"
fi

# chezmoi ignored は実在するエントリを実際に抑止したパターンしか出さない。ソース名で書いて何にも一致しない
# パターンは chezmoi 自身はエラーにしないので、ここでしか検出できない
case "$(uname -s)" in
  Darwin) expected=(CLAUDE.md README.md) ;;
  *) expected=(CLAUDE.md README.md .chezmoiscripts/06_check_1password_ssh_agent.sh) ;;
esac
want="$(printf '%s\n' "${expected[@]}" | LC_ALL=C sort)"
got="$(cm ignored | LC_ALL=C sort)"
if [ "$got" = "$want" ]; then
  echo "OK: chezmoi ignored ($(uname -s))"
else
  ng "ignored されるエントリが想定と違う
--- 期待
$want
--- 実際
$got"
fi

interpreter() {
  local words word
  read -r -a words <<< "${1#\#!}" || true
  [ "${#words[@]}" -eq 0 ] && return
  for word in "${words[@]}"; do
    case "$word" in
      -* | *=*) continue ;;
    esac
    word="${word##*/}"
    [ "$word" = env ] || {
      printf '%s\n' "$word"
      return
    }
  done
}

scripts=()
while IFS= read -r -d '' f; do
  if [[ "${f##*/}" =~ ^[a-z]+_ ]]; then
    ng "属性プレフィックスの綴り間違いに見える: ${f#"$dest"/}"
  fi
  [ -f "$f" ] || continue

  IFS= read -r shebang < "$f" || true
  case "$shebang" in '#!'*) ;; *) continue ;; esac
  [ -x "$f" ] ||
    ng "shebang 付きだが実行ビットが無い: ${f#"$dest"/} (executable_ の付け忘れ?)"

  # sh / bash / dash / ksh / busybox sh 以外は shellcheck が読めず SC1071 になる
  case "$(interpreter "$shebang")" in
    sh | bash | dash | ksh | busybox) scripts+=("$f") ;;
  esac
done < <(find "$dest" -mindepth 1 -print0)

if [ "${#scripts[@]}" -eq 0 ]; then
  ng "shellcheck 対象のシェルスクリプトが 1 つも見つからない (走査が壊れている?)"
else
  printf 'shellcheck: %s\n' "${scripts[@]}"
  shellcheck "${scripts[@]}" || rc=1
fi

if command -v zsh >/dev/null 2>&1; then
  zsh_ok=1
  for f in "$dest"/.zshenv "$dest"/.config/zsh/.zshenv "$dest"/.config/zsh/.zshrc \
    "$dest"/.config/zsh/*.zsh "$dest"/.config/zsh/hooks/*.zsh; do
    if [ ! -f "$f" ]; then
      ng "zsh 設定が配置されていない: ${f#"$dest"/}"
      zsh_ok=0
      continue
    fi
    zsh -n "$f" || {
      ng "zsh の構文エラー: ${f#"$dest"/}"
      zsh_ok=0
    }
  done
  [ "$zsh_ok" -eq 1 ] && echo "OK: zsh -n"
else
  ng "zsh が無いので zsh 設定の構文チェックができない"
fi

# promptBoolOnce は既存の config の値を再利用するので、config を消してから init し直す
rm "$work/chezmoi.toml"
cm init --promptBool "Do you want to install external casks=true" \
  --promptBool "Is this a work machine=false"
cm apply --exclude scripts
if [ -e "$dest/.config/zsh/work.zsh" ]; then
  ng "work=false で apply しても work.zsh が残る"
else
  echo "OK: work=false で work.zsh が消える"
fi

exit "$rc"
