#!/bin/sh

# 実効ユーザ root 以外での実行を抑止
if [ "$(id -un)" != "root" ]; then 
  echo "This script must be run as root user."
  exit 1
fi

rm -f /etc/nginx/sites-enabled/default
systemctl reload nginx
