# dotfiles

[chezmoi](https://www.chezmoi.io/)で管理。

対象OS: MacOS(intel), Ubuntu

## Requirements

- zsh: `chezmoi apply` 時に自動でインストール (Ubuntu のみ) / ログインシェルへ設定する。
  `sudo` が使えない環境では変更をスキップして案内だけ出すので、その場合は
  `chsh -s "$(command -v zsh)"` を手動で実行する。反映は次回ログインから。

## Installation

### 1password cli の設定を行う(MacOS の場合)

[公式](https://developer.1password.com/docs/cli/get-started/)を参考にして、1password cli と desktop アプリをインストールし、設定を行う。

### 環境構築

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kazu-2020
```
