# dotfiles

[chezmoi](https://www.chezmoi.io/)で管理。

対象OS: MacOS(intel), Ubuntu

## Requirements

- zsh: ログインシェルに設定しておくこと

## Installation

### 1password cli の設定を行う(MacOS の場合)

[公式](https://developer.1password.com/docs/cli/get-started/)を参考にして、1password cli と desktop アプリをインストールし、設定を行う。

### 環境構築

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kazu-2020
```
