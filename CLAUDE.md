# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリの性質

[chezmoi](https://www.chezmoi.io/) で管理する dotfiles のソースディレクトリ。ビルドは存在しないが、CI (`.github/workflows/ci.yml`) が macOS (arm64/amd64) と Ubuntu の各ランナーで全テンプレート (`*.tmpl` と `.chezmoiignore` / `.chezmoiremove`) の `chezmoi execute-template` 検証・展開後スクリプトの shellcheck・`.chezmoidata` のデータ構文チェックを行う。対象 OS は macOS (Intel / Apple Silicon) と Ubuntu で、OS 差分は Go テンプレートで吸収する。

このディレクトリ自体が chezmoi のソースディレクトリ (`~/.local/share/chezmoi`) なので、ここでファイルを編集しても `chezmoi apply` するまでホームディレクトリには反映されない。

## よく使うコマンド

```sh
chezmoi execute-template < dot_config/zsh/dot_zshenv.tmpl   # テンプレート展開結果の確認
chezmoi data              # テンプレートで参照できる変数の一覧
```

`.chezmoiscripts/` のスクリプトは `run_once_` なので、内容を変更しない限り再実行されない。強制的に再実行させるには `chezmoi state delete-bucket --bucket=scriptState` を使う。

## ファイル命名規則 (chezmoi の属性プレフィックス)

ファイル名がそのまま配置先とパーミッションを決める。リネーム時は要注意。

- `dot_foo` → `~/.foo`、`dot_config/` → `~/.config/`
- `executable_foo` → 実行ビットを立てて配置 (例: `dot_config/borders/executable_bordersrc`)
- `*.tmpl` → Go テンプレートとして展開してから配置 (拡張子は落ちる)
- `.chezmoiignore` / `.chezmoiremove` / `.chezmoi.toml.tmpl` / `.chezmoiscripts/` / `.chezmoidata/` は chezmoi 自身の設定で、ホームには配置されない
- `.chezmoiremove` に書いたパスは `chezmoi apply` で**削除される**。ソースから消しただけでは配置済みファイルは残るため、その後始末に使う (全環境に行き渡ったらエントリごと消してよい)

## テンプレートのデータソース

テンプレート変数の実体は 2 箇所にあり、chezmoi が両者を再帰的にマージする。

1. `.chezmoidata/packages.yaml` — インストールするパッケージ一覧 (`brew.packages` の `common` / `mac` / `cask.common`)。**パッケージを追加する場合はここを編集する。**
2. `.chezmoi.toml.tmpl` が生成する `~/.config/chezmoi/chezmoi.toml` — prompt や OS 判定に依存して `.chezmoidata` に置けないもの:
   - `[data.brew.packages.cask] external` / `installExternal` — `chezmoi init` 時の `promptBoolOnce` で入れるか選ばせる。回答は `installExternal` として書き出され、次回以降の `chezmoi init` はそれを引き継ぐので再質問されない (質問し直したい場合は `chezmoi.toml` からこのキーを消す)
   - `[data.brew] path` — OS/アーキテクチャごとの brew パス (`/opt/homebrew`, `/usr/local`, `/home/linuxbrew/.linuxbrew`)。`sync.zsh.tmpl` の `eval "$({{ .brew.path }} shellenv)"` などがこれを参照する

`.chezmoidata/` は chezmoi が毎回自動で読むので、1 を編集した場合は `chezmoi apply` するだけで反映される。

**一方 `.chezmoi.toml.tmpl` (2) を変更しても既存環境の `chezmoi.toml` は自動更新されない。** 反映には `chezmoi init` の再実行が必要。

なお **`chezmoi.toml` の `data` は `.chezmoidata` より優先される**。両者で同じキーを定義すると `.chezmoidata` 側がエラーにならず静かに無視されるので、キーを重複させないこと。

## zsh 設定の構造

XDG 準拠のため `ZDOTDIR` を `~/.config/zsh` に寄せている。読み込み経路:

```
~/.zshenv (dot_zshenv.tmpl)      XDG 変数と ZDOTDIR を定義し $ZDOTDIR/.zshenv を source
  └─ ~/.config/zsh/.zshenv        各ツールの XDG 準拠な環境変数 (GOPATH, CARGO_HOME, ...)
       └─ ~/.config/zsh/.zshrc    sync.zsh を source → sheldon で残りを非同期ロード
```

- `sync.zsh.tmpl` — 起動時に同期実行が必要なもの (PATH 構築、brew shellenv、history、setopt)
- `sheldon/plugins.toml` — プラグイン管理。`zsh-defer` を使った `defer` テンプレートで大半を遅延ロードする
- `hooks/async.zsh.tmpl` — エイリアスと mise 有効化。sheldon の `[plugins.async]` から遅延 source される
- `hooks/zeno-pre.zsh` / `zeno-post.zsh` — zeno の環境変数とキーバインド。プラグインの `hooks.pre` / `hooks.post` から呼ばれる

**TAB (`^i`) の補完 UI は fzf-tab に寄せる方針**。zeno は `config.yml` の `snippets:` を使うスニペット展開と履歴選択・ghq cd に限定して使い、`zeno-completion` は bind しない。両方を bind すると `zsh-defer` の FIFO 実行で後から読まれた方が勝つため、読み込み順に依存した壊れ方をする。

`sheldon/plugins.toml` の `[templates] defer` 内の `{{ }}` は sheldon (Tera) のテンプレート構文であり、chezmoi のものではない。このファイルは `.tmpl` ではないので chezmoi は展開しないが、`.tmpl` 化する場合は `{{` のエスケープが必要になる。

新しいシェル設定を追加する際は、遅延させてよいものは `hooks/async.zsh.tmpl` に、PATH や `setopt` など即時に必要なものは `sync.zsh.tmpl` に置く。

## 言語ランタイム (mise)

Go / Node / Ruby / uv などのランタイムは mise に一本化しており、バージョンは `dot_config/mise/config.toml` が唯一の情報源。mise 本体は brew bundle で入り、`.chezmoiscripts/run_once_after_04_install_mise_tools.sh.tmpl` が `chezmoi apply` の中で `mise install` まで済ませる。

**`mise use -g` は使わないこと。** 書き込み先が `~/.config/mise/config.toml` そのものなので、その場では切り替わっても次の `chezmoi apply` でソース側の内容に静かに巻き戻る (`chezmoi update` を回していると特に気づきにくい)。バージョンを変えるときはソースの `dot_config/mise/config.toml` を編集して apply する。

`mise activate` の auto-install (`not_found_auto_install`) は対話シェルでコマンドを叩いたときしか効かない。Neovim から起動する LSP や Makefile 経由の実行はそれでは救えないため、apply 時の `mise install` を省略しない。

## 1Password 連携 (macOS)

- SSH agent: `dot_config/zsh/dot_zshenv.tmpl` で `SSH_AUTH_SOCK` を 1Password の agent.sock に向けている (darwin のみ)
- コミット署名: `dot_config/git/config.tmpl` で `gpg.format = ssh` + `commit.gpgsign = true`。署名プログラムは `op` コマンドが存在する macOS でのみ `op-ssh-sign` を設定する条件付きブロックになっている (Linux では署名プログラム未設定)

## 変更時の注意

- テンプレート内の `{{ if eq .chezmoi.os "darwin" }}` 系の分岐を追加/変更したら、`chezmoi execute-template` で両 OS 相当の出力を確認する
- 秘密情報は直接書かず 1Password (`onepasswordRead` 等) を経由させる方針
- コミットメッセージは日本語の短い要約が慣例
