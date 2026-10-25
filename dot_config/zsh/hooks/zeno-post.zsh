if [[ -n $ZENO_LOADED ]]; then
  bindkey ' '  zeno-auto-snippet
  bindkey '^m' zeno-auto-snippet-and-accept-line
  bindkey '^x '  zeno-insert-space
  bindkey '^x^m' accept-line
  bindkey '^x^z' zeno-toggle-auto-snippet

  bindkey '^r' zeno-history-selection
  # ^x^s は sync.zsh の no_flow_control (端末のフロー制御が ^s を奪う) が前提
  bindkey '^x^s' zeno-insert-snippet
  bindkey '^]' zeno-ghq-cd
fi

