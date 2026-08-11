#!/usr/bin/env bash
#
# chezmoi apply 自体を検証する。
#
# テンプレート展開 (execute-template) だけでは属性プレフィックス (create_ /
# executable_) の誤りや .chezmoiignore のパターンずれが捕まらないため、使い捨ての
# 一時ディレクトリへ実際に配置して結果を検査する。CI から呼ぶが、引数なしで手元から
# 実行しても同じ検査が回る。
#
# 使い方: .github/scripts/verify-apply.sh [ソースディレクトリ]
set -euo pipefail

src="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
rc=0

# 配置先・config・永続ステートをすべて使い捨ての一時ディレクトリに閉じ込める。
# --destination だけでは永続ステート (~/.config/chezmoi/chezmoistate.boltdb) が
# $HOME 側のままなので、--persistent-state まで渡して初めて切り離せる
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

# config も自前で作る。$HOME の chezmoi.toml に依存すると、init 済みの環境と未 init の
# クローンで結果が変わり、CI と手元で見ているデータが食い違う (未 init だと .brew.path
# が引けず、アサーション以前にテンプレートエラーで落ちる)。execute-template ではなく
# init を使うのは、こちらは config テンプレートのハッシュを永続ステートにも記録するため。
# 記録が無いと以降の apply / status が「config が古い」と毎回警告する
#
# work=true にするのは、仕事用の private_work.zsh.tmpl を実際に配置させて private_
# 属性まで通すため。false にすると .chezmoiignore で除外され、この検証を素通りする
# (その場合は後述の expected にも .config/zsh/work.zsh を足す必要がある)
cm init --promptBool "Do you want to install external casks=true" \
  --promptBool "Is this a work machine=true"

# スクリプトは brew install などの副作用を伴うため配置対象から外す
# (スクリプト本文の検証はワークフロー側の shellcheck が担当する)
cm apply --exclude scripts
echo "OK: chezmoi apply"

# 冪等性。apply 済みの配置先に対して status が何か報告するなら、展開結果が
# 非決定的か、書けていないエントリがある
st="$(cm status --exclude scripts)"
if [ -z "$st" ]; then
  echo "OK: 2 回目の status が空"
else
  ng "apply 後も status が差分を報告する
$st"
fi

# .chezmoiignore の検証。chezmoi ignored が挙げるのは「実在するエントリを実際に
# 抑止したパターン」だけなので、ソース名で書いてしまって何にも一致しないパターンは
# ここから消える。「ソース名を書いても静かに無視される」を直接突けるのはこの一覧だけ
case "$(uname -s)" in
  # 06 は darwin 限定なので、Linux ではスクリプトごと ignore される
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

# shebang からインタプリタ名を取り出す。`#!/usr/bin/env -S bash -e` のような
# env 形式やオプション付きも吸収する
interpreter() {
  local words word
  read -r -a words <<< "${1#\#!}" || true
  [ "${#words[@]}" -eq 0 ] && return
  for word in "${words[@]}"; do
    case "$word" in
      -* | *=*) continue ;; # env のオプションと VAR=value を読み飛ばす
    esac
    word="${word##*/}"
    [ "$word" = env ] || {
      printf '%s\n' "$word"
      return
    }
  done
}

# 配置結果の走査。ここで 3 つ見る:
#
# 1. ファイル名が `xxx_` で始まっていないこと。属性プレフィックスの綴りを間違えると
#    (creat_ / exectuable_ など) chezmoi はただの名前として扱い、そのまま配置先に
#    残る。配置先に snake_case の名前が必要になったらこの判定を見直すこと
# 2. shebang があるのに実行できない = ソース側で executable_ を付け忘れている
# 3. shellcheck が扱えるインタプリタのものを shellcheck にかけること。.tmpl でない
#    生のシェルスクリプトは他のどのステップでも検査されない
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

  # 対象は sh / bash / dash / ksh / busybox sh のみ (shellcheck が読めるのがこれだけで、
  # 他は SC1071 になる)。zsh や fish のスクリプトを足したときに落ちないよう、shebang の
  # 末尾が sh かどうかではなくインタプリタ名で判定する (末尾一致では fish や csh も拾う)
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

exit "$rc"
