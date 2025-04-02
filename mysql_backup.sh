#!/bin/sh

# 実効ユーザ mysql_backup 以外での実行を抑止
if [ "$(id -un)" != "mysql_backup" ]; then
  echo "This script must be run as mysql_backup user."
  exit 1
fi

# バックアップ保存先のディレクトリに移動:
cd /var/backups/mysql

########## バックアップ ##########

# 丸８日より前のバックアップは削除
find . -type f -mtime +7 -exec rm {} \;

# 現在の日付と時間をフォーマット
DATE=$(date +"%Y-%m-%d_%H%M%S")

# 引数のデータベース名を処理
for DB in "$@"; do

  # 暗号化コマンド（冒頭部分）
  CRYPT="tee > /dev/null "

  # 暗号鍵ごとの処理
  for KEY in *@* ; do

    # 鍵の有無確認
    if ! gpg --list-keys "${KEY}" > /dev/null 2>&1; then
        continue # 鍵束にない鍵なら飛ばす
    fi

    # バックアップファイル
    BACKUP_FILE="${KEY}/mysql_backup_${DATE}_${DB}.sql.gz.gpg"

    # パーミッションを先に変更
    touch     "$BACKUP_FILE"
    chmod 640 "$BACKUP_FILE"

    # 暗号化コマンド
    CRYPT="${CRYPT} >( gpg --encrypt \
                           --trust-model always \
                           --recipient ${KEY} > ${BACKUP_FILE} )"
  done

  # バックアップ ( --set-gtid-purged=OFF MariaDB にないオプションにつき削除）
  mysqldump -u mysql_backup \
            --single-transaction \
            --no-tablespaces \
            --add-drop-database \
            --databases "${DB}" \
            | gzip \
	    | bash -c "${CRYPT}"
done

# 結果表示
#clear
ls -1tlhr */* | awk '{print $9, "(" $5 ")"}' | \
  cat -n | tac | head -n 5 | expand | bash -c "tee >(logger)"

########## リモートコピー ##########

# ディレクトリ再確認
BKUPD=`pwd`/ # rsync で同期するため最後 "/" 必要

# ホストごとの処理
for HOST in `ls -1 ${BKUPD} | sed -e 's/.*\@//' | sort | uniq`; do

  # ファイルコピー（同期）
  if rsync -az \
    --delete-excluded \
    --include "*@${HOST}/" \
    --include "*@${HOST}/*.gpg" \
    --exclude '*' \
    "${BKUPD}" "${HOST}:${BKUPD}"; then
    echo done "${HOST}"
  else
    echo failed "${HOST}"
  fi \
  | bash -c "tee >(logger)"

done
