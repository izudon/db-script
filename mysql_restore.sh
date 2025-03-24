#!/bin/sh

# 実効ユーザ mysql_restore 以外での実行を抑止
if [ "$(id -un)" != "mysql_restore" ]; then
  echo "This script must be run as mysql_restore user."
  exit 1
fi

# バックアップ保存先のディレクトリに移動:
cd /var/backups/mysql

# DB ごとに最新のファイルを選びリストア
for DB in "$@" ; do

  # 新しいものを優先して順に試していく
  for FILE in `ls -1t */*_${DB}.sql.gz.gpg` ; do

    # 復号化・解凍・リストア
    gpg --decrypt "$FILE" | gunzip -c - | mysql -u mysql_restore

    # 成功したら次のＤＢへ
    if [ $? -eq 0 ]; then
      echo "success: ${FILE}" | bash -c "tee >(logger)"
      break
    fi

  done

done
