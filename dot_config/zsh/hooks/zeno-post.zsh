if [[ -n $ZENO_LOADED ]]; then
  bindkey ' '  zeno-auto-snippet
  bindkey '^m' zeno-auto-snippet-and-accept-line
  # TAB (^i) は fzf-tab に寄せるので zeno-completion は bind しない。
  # ここで bind すると sheldon の読み込み順次第で fzf-tab と奪い合いになる
  # (現状は fzf-tab が後勝ちしているだけで、順序が変わると壊れる)。
  # zeno は snippets: を使うスニペット展開と履歴選択に限定して使う。
  bindkey '^x '  zeno-insert-space
  bindkey '^x^m' accept-line
  bindkey '^x^z' zeno-toggle-auto-snippet

  bindkey '^r' zeno-history-selection
  bindkey '^[' zeno-insert-snippet
  bindkey '^]' zeno-ghq-cd
fi

