alias rm='rm -i'
alias ll='ls -lh'
alias la='ls -a'

if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
  alias v='nvim'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
fi

if command -v fd >/dev/null 2>&1; then
  alias find='fd'
fi

if command -v procs >/dev/null 2>&1; then
  alias ps='procs'
fi

if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
fi
