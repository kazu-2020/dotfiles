if [[ -n $ZENO_LOADED ]]; then
  bindkey ' '  zeno-auto-snippet
  bindkey '^m' zeno-auto-snippet-and-accept-line
  bindkey '^i' zeno-completion
  bindkey '^x '  zeno-insert-space
  bindkey '^x^m' accept-line
  bindkey '^x^z' zeno-toggle-auto-snippet

  bindkey '^r' zeno-history-selection
  bindkey '^[' zeno-insert-snippet
  bindkey '^]' zeno-ghq-cd
fi

