#!/usr/bin/env bash
#
# chezmoi apply 自体を検証する。
#
# テンプレート展開 (execute-template) だけでは属性プレフィックス (create_ /
# executable_) の誤りや .chezmoiignore のパターンずれが捕まらないため、使い捨ての
# 一時ディレクトリへ実際に配置して結果を検査する。CI から呼ぶが、引数なしで手元から
# 実行しても同じ検査が回る (配置先は毎回 mktemp -d なので $HOME には触らない)。
#
# 使い方: .github/scripts/verify-apply.sh [ソースディレクトリ]
set -euo pipefail

src="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
dest="$(mktemp -d)"
rc=0

ng() {
  echo "NG: $*" >&2
  rc=1
}

# スクリプトは brew install などの副作用を伴うため配置対象から外す
# (スクリプト本文の検証はワークフロー側の shellcheck が担当する)
chezmoi apply --source "$src" --destination "$dest" --exclude scripts
echo "OK: chezmoi apply --destination $dest"

# 冪等性。apply 済みの配置先に対して status が何か報告するなら、展開結果が
# 非決定的か、書けていないエントリがある
st="$(chezmoi status --source "$src" --destination "$dest" --exclude scripts)"
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
got="$(chezmoi ignored --source "$src" --destination "$dest" | LC_ALL=C sort)"
if [ "$got" = "$want" ]; then
  echo "OK: chezmoi ignored ($(uname -s))"
else
  ng "ignored されるエントリが想定と違う
--- 期待
$want
--- 実際
$got"
fi

# 配置結果の走査。ここで 2 つ見る:
#
# 1. ファイル名が `xxx_` で始まっていないこと。属性プレフィックスの綴りを間違えると
#    (creat_ / exectuable_ など) chezmoi はただの名前として扱い、そのまま配置先に
#    残る。配置先に snake_case の名前が必要になったらこの判定を見直すこと
# 2. shebang が sh 系のファイルを shellcheck にかけること。.tmpl でない生の
#    シェルスクリプトは他のどのステップでも検査されない。あわせて、shebang が
#    あるのに実行できない = ソース側で executable_ を付け忘れた、も拾う
scripts=()
while IFS= read -r -d '' f; do
  if [[ "${f##*/}" =~ ^[a-z]+_ ]]; then
    ng "属性プレフィックスの綴り間違いに見える: ${f#"$dest"/}"
  fi
  [ -f "$f" ] || continue

  IFS= read -r shebang < "$f" || true
  case "$shebang" in
    # zsh は shellcheck が扱えないので外す。bash も dash も env 形式も末尾は sh
    '#!'*zsh*) ;;
    '#!'*sh | '#!'*sh\ *)
      scripts+=("$f")
      [ -x "$f" ] ||
        ng "shebang 付きだが実行ビットが無い: ${f#"$dest"/} (executable_ の付け忘れ?)"
      ;;
  esac
done < <(find "$dest" -mindepth 1 -print0)

if [ "${#scripts[@]}" -eq 0 ]; then
  ng "shebang 付きのシェルスクリプトが 1 つも見つからない (走査が壊れている?)"
else
  printf 'shellcheck: %s\n' "${scripts[@]}"
  shellcheck "${scripts[@]}" || rc=1
fi

exit "$rc"
