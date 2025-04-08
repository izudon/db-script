#!/bin/sh

# root 以外の実効ユーザでの実行を阻止 
[ "$(id -u)" -ne 0 ] && echo "This script must be run as root user." \
&& exit 1

# 引数１つなければ終了
[ $# -ne 1 ] && { echo "Usage: $0 filename"; exit 1; }

dir=$(basename "$PWD")
name=${dir%-available}

# 条件1 カレントディレクトリが xxx-available
# 条件2 ../xxx-enabled というディレクトリが存在
# シンボリックリンクを削除
    [ "$dir" != "$name" ] \
    && [ -d ../"$name"-enabled ] \
    && rm -iv ../"$name"-enabled/"$1"
