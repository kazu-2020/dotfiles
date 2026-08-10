# dotfiles

[chezmoi](https://www.chezmoi.io/) で管理している個人用 dotfiles。

対象 OS: macOS (Intel / Apple Silicon), Ubuntu

`chezmoi apply` 一発で、Homebrew の導入からパッケージ・言語ランタイムのインストール、
ログインシェルの設定までが済むようにしてある。OS / アーキテクチャの差分は Go テンプレートで吸収する。

## Installation

### 1. 1Password の設定 (macOS のみ)

SSH 認証と git のコミット署名を 1Password に寄せているため、先に設定しておく。
[公式ドキュメント](https://developer.1password.com/docs/cli/get-started/)を参考に、
1Password デスクトップアプリと CLI をインストールし、SSH agent を有効にする。

Linux では SSH agent もコミット署名プログラムも設定されない (署名自体は有効なので、
必要なら machine-local な設定で上書きする)。

### 2. 環境構築

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply kazu-2020
```

初回の `chezmoi init` で「external な cask を入れるか」を聞かれる。
回答は `~/.config/chezmoi/chezmoi.toml` に記録されるので、次回以降は聞かれない
(聞き直したい場合は `chezmoi.toml` の `installExternal` を消してから `chezmoi init` する)。

## apply で何が起きるか

`.chezmoiscripts/` のスクリプトが番号順に走る。

| スクリプト | 内容 |
| --- | --- |
| `before_02_install_homebrew` | Homebrew を入れる (Ubuntu では前提の apt パッケージも入れる) |
| `after_01_create_XDG_directories` | `~/.config` などの XDG ディレクトリを作る |
| `after_02_execute_brew_bundle` | `.chezmoidata/packages.yaml` の内容で `brew bundle` |
| `after_03_migrate_irb_history` | irb の履歴ファイルを新しいパスへ移す (旧環境からの移行用) |
| `after_04_install_mise_tools` | `~/.config/mise/config.toml` のランタイムを `mise install` |
| `after_05_set_login_shell` | ログインシェルを zsh にする (Ubuntu では zsh のインストールも) |

ログインシェルの変更は `sudo` を使う。`sudo` が使えない環境では apply を止めずに案内だけ出すので、
その場合は手動で実行する。反映は次回ログインから。

```sh
chsh -s "$(command -v zsh)"
```

## 構成

| パス | 内容 |
| --- | --- |
| `.chezmoidata/packages.yaml` | brew で入れるパッケージ一覧。**パッケージの追加はここ** |
| `.chezmoi.toml.tmpl` | prompt の結果や OS 判定に依存する設定 (brew のパスなど) |
| `.chezmoiscripts/` | apply 時に走るスクリプト |
| `dot_config/zsh/` | zsh 設定。`ZDOTDIR` を `~/.config/zsh` に寄せ、sheldon で非同期ロード |
| `dot_config/mise/config.toml` | 言語ランタイム (Go / Node / Ruby / uv) のバージョン。唯一の情報源 |
| `dot_config/git/`, `nvim/`, `eza/`, ... | 各ツールの設定 |

ファイル名のプレフィックスが配置先とパーミッションを決める chezmoi の規約に従う
(`dot_foo` → `~/.foo`、`executable_` → 実行ビット、`*.tmpl` → テンプレート展開)。

## メンテナンス

```sh
chezmoi apply                # ソースの内容をホームへ反映
chezmoi update               # git pull してから apply
chezmoi edit ~/.config/...   # ソース側のファイルを開く
chezmoi execute-template < dot_config/zsh/sync.zsh.tmpl   # テンプレート展開結果の確認
chezmoi data                 # テンプレートで参照できる変数の一覧
```

`run_once_` のスクリプトは内容を変えない限り再実行されない。強制的に走らせたい場合:

```sh
chezmoi state delete-bucket --bucket=scriptState
```

言語ランタイムのバージョンを変えるときは `mise use -g` ではなく
`dot_config/mise/config.toml` を編集して `chezmoi apply` する
(`mise use -g` の書き込み先は chezmoi 管理下のファイルなので、次の apply で巻き戻る)。

## CI

`.github/workflows/ci.yml` が macOS (arm64 / amd64) と Ubuntu の実ランナー上で、
全テンプレートの `chezmoi execute-template` 検証・展開後スクリプトの shellcheck・
`.chezmoidata` の構文チェックを行う。
