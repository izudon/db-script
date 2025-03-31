#!/bin/bash

# 引数チェック
if [ -z "$1" ]; then
  echo "エラー: 引数を指定してください。"
  exit 1
fi

# カレントディレクトリ名取得
current_dir=$(basename "$PWD")

# xxx-available かどうかチェック
if [[ "$current_dir" != *-available ]]; then
  echo "エラー: カレントディレクトリが xxx-available ではありません。"
  exit 1
fi

# 対応する xxx-enabled ディレクトリが存在するかチェック
enabled_dir="../${current_dir%-available}-enabled"
if [ ! -d "$enabled_dir" ]; then
  echo "エラー: 対応するディレクトリ $enabled_dir が存在しません。"
  exit 1
fi

# シンボリックリンクを削除
link_name="$enabled_dir/$1"

if [ -L "$link_name" ]; then
  rm -iv "$link_name"
else
  echo "情報: $link_name は存在しないか、シンボリックリンクではありません。"
fi
