#!/bin/bash

source "$(dirname "$0")/../config/paths.env"

# Ambil nama arsip dari parameter atau cari arsip terbaru
if [ -n "$1" ]; then
    NAMA_ARSIP=$(basename "$1")
else
    NAMA_ARSIP=$(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name 'backup_*.tar.gz' -printf '%T@ %f\n' | sort -nr | head -n 1 | cut -d' ' -f2-)
fi

ARCHIVE_FILE="$ARCHIVE_DIR/$NAMA_ARSIP"
FILE_CHECKSUM="$ARCHIVE_FILE.sha256"

echo "[INFO] Memverifikasi integritas arsip..."

# Periksa keberadaan arsip
if [ -z "$NAMA_ARSIP" ] || [ ! -f "$ARCHIVE_FILE" ]; then
    echo "[ERROR] Arsip backup tidak ditemukan!"
    exit 1
fi

echo "[INFO] Arsip: $NAMA_ARSIP"

# Periksa keberadaan file checksum
if [ ! -f "$FILE_CHECKSUM" ]; then
    echo "[ERROR] File checksum tidak ditemukan!"
    exit 2
fi

# Verifikasi checksum SHA-256
if (cd "$ARCHIVE_DIR" && sha256sum -c "$NAMA_ARSIP.sha256"); then
    echo "[SUCCESS] Integritas arsip terverifikasi!"
    exit 0
else
    echo "[ERROR] Integritas arsip gagal! File mungkin telah dimodifikasi."
    exit 4
fi
