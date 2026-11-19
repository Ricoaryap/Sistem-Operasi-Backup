#!/bin/bash
source "$(dirname "$0")/../config/paths.env"

# Buat timestamp untuk nama arsip
WAKTU=$(date +"%Y%m%d_%H%M%S")
NAMA_ARSIP="backup_${WAKTU}.tar.gz"
FILE_TUJUAN="$ARCHIVE_DIR/$NAMA_ARSIP"

echo "[INFO] Memulai pembuatan arsip backup..."

# Cek apakah folder tujuan (archive) ada dan punya izin writable
if [ ! -d "$ARCHIVE_DIR" ] || [ ! -w "$ARCHIVE_DIR" ]; then
    echo "[ERROR] Direktori tujuan ($ARCHIVE_DIR) tidak tersedia atau tidak dapat ditulis (Read-Only)!"
    exit 3
fi

# Buat arsip .tar.gz dari folder source
tar -czf "$FILE_TUJUAN" -C "$SOURCE_DIR" . 2>/dev/null

# Cek apakah perintah tar berhasil
if [ $? -eq 0 ] && [ -f "$FILE_TUJUAN" ]; then
    echo "[SUCCESS] Arsip berhasil dibuat: $FILE_TUJUAN"
    exit 0
else
    echo "[ERROR] Gagal membuat arsip backup!"
    exit 3
fi
