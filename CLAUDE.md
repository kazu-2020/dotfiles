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

`.chezmoiscripts/` のスクリプトは大半が `run_once_` で、内容を変更しない限り再実行されない。強制的に再実行させるには `chezmoi state delete-bucket --bucket=scriptState` を使う (`run_after_06_check_1password_ssh_agent.sh.tmpl` だけは毎回実行する `run_after_`)。

## ファイル命名規則 (chezmoi の属性プレフィックス)

ファイル名がそのまま配置先とパーミッションを決める。リネーム時は要注意。

- `dot_foo` → `~/.foo`、`dot_config/` → `~/.config/`
- `executable_foo` → 実行ビットを立てて配置 (例: `dot_config/borders/executable_bordersrc`)
- `*.tmpl` → Go テンプレートとして展開してから配置 (拡張子は落ちる)
- `.chezmoiignore` / `.chezmoiremove` / `.chezmoi.toml.tmpl` / `.chezmoiscripts/` / `.chezmoidata/` は chezmoi 自身の設定で、ホームには配置されない
- `.chezmoiremove` に書いたパスは `chezmoi apply` で**削除される**。ソースから消しただけでは配置済みファイルは残るため、その後始末に使う (全環境に行き渡ったらエントリごと消してよい)

## テンプレートのデータソース

テンプレート変数の実体は 2 箇所にあり、chezmoi が両者を再帰的にマージする。

1. `.chezmoidata/` 以下のデータファイル (chezmoi が `.yaml` / `.yml` / `.json` / `.toml` をすべて読む)
   - `packages.yaml` — インストールするパッケージ一覧 (`brew.packages` の `common` / `mac` / `cask.common`)。**パッケージを追加する場合はここを編集する。**
   - `onepassword.yaml` — 1Password の SSH agent ソケットのパス。zshenv とチェックスクリプトの 2 箇所から参照されるので、値をここに寄せている
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

zsh の状態ファイル (`HISTFILE` と `zcompdump`) は `$XDG_STATE_HOME/zsh/` にまとめる。**このディレクトリを作るのは `sync.zsh.tmpl` だけ**なので、`.zshrc` での `sync.zsh` → `sheldon source` の順序を崩さないこと。崩すと compinit が dump を黙って作らず毎回フルスキャンに戻る (エラーは出ない)。

配置先を変えるときは `run_once_after_0N_migrate_*.sh.tmpl` を 1 本足して既存環境のファイルを移す (irb / zsh 履歴の前例がある)。移行スクリプトは apply 時にまだ `~/.zshenv` が読まれていない前提で、`XDG_*` ではなく `.chezmoi.destDir` からパスを組み立てる。

**TAB (`^i`) の補完 UI は fzf-tab に寄せる方針**。zeno は `config.yml` の `snippets:` を使うスニペット展開と履歴選択・ghq cd に限定して使い、`zeno-completion` は bind しない。両方を bind すると `zsh-defer` の FIFO 実行で後から読まれた方が勝つため、読み込み順に依存した壊れ方をする。

`sheldon/plugins.toml` の `[templates] defer` 内の `{{ }}` は sheldon (Tera) のテンプレート構文であり、chezmoi のものではない。このファイルは `.tmpl` ではないので chezmoi は展開しないが、`.tmpl` 化する場合は `{{` のエスケープが必要になる。

新しいシェル設定を追加する際は、遅延させてよいものは `hooks/async.zsh.tmpl` に、PATH や `setopt` など即時に必要なものは `sync.zsh.tmpl` に置く。

## 言語ランタイム (mise)

Go / Node / Ruby / uv などのランタイムは mise に一本化しており、バージョンは `dot_config/mise/config.toml` が唯一の情報源。mise 本体は brew bundle で入り、`.chezmoiscripts/run_onchange_after_04_install_mise_tools.sh.tmpl` が `chezmoi apply` の中で `mise install` まで済ませる。

このスクリプトが `run_once_` ではなく `run_onchange_` なのは、再実行判定が**展開後のスクリプト本文のハッシュ**で行われるため。`run_once_` だと `dot_config/mise/config.toml` のバージョンを上げても本文が変わらず再実行されず、新しい config が配置されたのにランタイムが入らない状態になる。本文に `include "dot_config/mise/config.toml" | sha256sum` のテンプレート呼び出しをコメントとして埋めて、config の変更を再実行の契機にしている。`run_once_` のままハッシュだけ埋めても変更時には走るが、`run_once_` は過去に実行した本文をすべて記憶しているため**バージョンを前の値に戻したときに再実行されない**。`run_onchange_` は直前の本文としか比較しないので revert でも走る。ランタイム以外にも「ソースの別ファイルの変更で再実行したいスクリプト」を書く場合は同じ手を使う。

**`mise use -g` は使わないこと。** 書き込み先が `~/.config/mise/config.toml` そのものなので、その場では切り替わっても次の `chezmoi apply` でソース側の内容に静かに巻き戻る (`chezmoi update` を回していると特に気づきにくい)。バージョンを変えるときはソースの `dot_config/mise/config.toml` を編集して apply する。

`mise activate` の auto-install (`not_found_auto_install`) は対話シェルでコマンドを叩いたときしか効かない。Neovim から起動する LSP や Makefile 経由の実行はそれでは救えないため、apply 時の `mise install` を省略しない。

## 1Password 連携 (macOS)

- インストール: `.chezmoidata/packages.yaml` の cask (`1password` / `1password-cli`) で入る
- SSH agent: `dot_config/zsh/dot_zshenv.tmpl` で `SSH_AUTH_SOCK` を 1Password の agent.sock に向けている (darwin のみ)。ソケットのパスは `.chezmoidata/onepassword.yaml` が唯一の情報源で、zshenv と後述のチェックスクリプトの両方がここを参照する
- コミット署名: `dot_config/git/config.tmpl` で `gpg.format = ssh` + `commit.gpgsign = true`。署名プログラムは `op` コマンドが存在する macOS でのみ `op-ssh-sign` を設定する条件付きブロックになっている (Linux では署名プログラム未設定)

**SSH agent の有効化そのものは自動化していない。** トグルの実体は 1Password の `settings.json` (`sshAgent.enabled`) だが、初回サインインを済ませるまでこのファイルが存在せず (サインインは GUI 必須)、アプリ起動中の書き換えはメモリ上の状態に上書きされ、かつ非公式フォーマットなのでキー名がアップデートで黙って変わりうる。

代わりに `run_after_06_check_1password_ssh_agent.sh.tmpl` が apply のたびに agent.sock の有無を見て、無効なら有効化手順を stderr に出す。有効なら無音、どのケースでも `exit 0` で apply は止めない。`run_once_` にしないのは、初回 apply の時点ではまだサインインが済んでおらず、一度きりの警告だと有効化し忘れたまま気づけなくなるため。

このスクリプトだけ **darwin 限定の方法が他と違う**。他のスクリプトはテンプレートの `{{ if eq .chezmoi.os "darwin" }}` で本文を空にしているが、これは毎回走る `run_after_` なので、それだと Linux で apply のたびに空のプロセスが起きる。代わりに `.chezmoiignore` でスクリプトごと除外している。**`.chezmoiignore` に書くパターンはソース名ではなく展開後のターゲット名** (`.chezmoiscripts/06_check_1password_ssh_agent.sh`) で、ソース名を書いても一致せず静かに無視される。効いているかは `chezmoi managed --include=scripts` で確認できる。

## 変更時の注意

- テンプレート内の `{{ if eq .chezmoi.os "darwin" }}` 系の分岐を追加/変更したら、`chezmoi execute-template` で両 OS 相当の出力を確認する
- 秘密情報は直接書かず 1Password (`onepasswordRead` 等) を経由させる方針
- コミットメッセージは日本語の短い要約が慣例
