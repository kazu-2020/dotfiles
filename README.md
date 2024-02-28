# dotfiles

[chezmoi](https://www.chezmoi.io/)で管理しています。
MacOS(intel), Ubuntu を想定しています。

## Requirements

- curl
- zsh: Login Shell に設定してください

## Installation

### brew をインストールする

https://brew.sh/

```sh
# Ubuntu
sudo apt-get update && apt-get install -y build-essential procps curl file git

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

```sh
# macOS
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 1password cli の設定を行う

[公式](https://developer.1password.com/docs/cli/get-started/)を参考にして、1password cli と desktop アプリをインストールし、設定を行う。

### 環境構築

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kazu-2020
```
