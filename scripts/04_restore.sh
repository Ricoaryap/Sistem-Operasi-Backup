#!/bin/bash

# Pemulihan Data (Restore)
# Penanggung jawab: Vrista Darin Nadira (2510512119)
# Penggunaan: ./scripts/04_restore.sh <file_arsip.tar.gz>
# Exit status:
# 0 = Restore berhasil
# 1 = Parameter tidak sesuai
# 5 = Arsip/checksum/restore gagal

# Mengaktifkan error handling
set -o pipefail

# Memuat konfigurasi direktori proyek
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_DIR/config/paths.env"

# Lokasi log khusus restore
RESTORE_LOG="$OUTPUT_DIR/restore.log"

EXIT_OK=0
EXIT_PARAM=1
EXIT_RESTORE=5

# Fungsi pencatatan log
catat_log() {
    local level="$1"
    local pesan="$2"

    local waktu
    waktu="$(date '+%Y-%m-%d %H:%M:%S')"

    local baris="[$waktu] [$level] [PID $$] $pesan"

    echo "$baris"

    mkdir -p "$OUTPUT_DIR" 2>/dev/null
    echo "$baris" >> "$RESTORE_LOG" 2>/dev/null || true
}

# Fungsi menangani kegagalan
gagal() {
    catat_log "ERROR" "$2"
    exit "$1"
}

# Validasi jumlah parameter
if [ "$#" -ne 1 ]; then
    gagal "$EXIT_PARAM" \
    "Penggunaan: $0 <file_arsip.tar.gz>"
fi

ARCHIVE_FILE="$1"

# Validasi keberadaan arsip
if [ ! -f "$ARCHIVE_FILE" ] || [ ! -r "$ARCHIVE_FILE" ]; then
    gagal "$EXIT_RESTORE" \
    "Arsip tidak ditemukan atau tidak dapat dibaca: $ARCHIVE_FILE"
fi

# Mengubah path arsip menjadi path absolut
ARCHIVE_FILE="$(realpath "$ARCHIVE_FILE")" || \
    gagal "$EXIT_RESTORE" "Path arsip tidak valid"

ARCHIVE_NAME="$(basename "$ARCHIVE_FILE")"

# Validasi ekstensi arsip
if [[ "$ARCHIVE_NAME" != *.tar.gz ]]; then
    gagal "$EXIT_RESTORE" "Format arsip harus .tar.gz"
fi

# Memastikan direktori tujuan tersedia
mkdir -p "$RESTORE_DIR" "$OUTPUT_DIR" || \
    gagal "$EXIT_RESTORE" "Gagal menyiapkan direktori restore"

if [ ! -w "$RESTORE_DIR" ] || [ ! -x "$RESTORE_DIR" ]; then
    gagal "$EXIT_RESTORE" "Direktori restore tidak dapat ditulis"
fi

# Memeriksa file checksum
CHECKSUM_FILE="${ARCHIVE_FILE}.sha256"

if [ ! -f "$CHECKSUM_FILE" ] || [ ! -r "$CHECKSUM_FILE" ]; then
    gagal "$EXIT_RESTORE" "File checksum tidak ditemukan"
fi

catat_log "INFO" "Memulai proses restore: $ARCHIVE_NAME"

# Verifikasi integritas arsip
if ! (cd "$(dirname "$ARCHIVE_FILE")" && sha256sum -c "$(basename "$CHECKSUM_FILE")"); then
    gagal "$EXIT_RESTORE" \
    "Verifikasi checksum gagal. Restore dibatalkan"
fi

catat_log "INFO" "Checksum arsip valid"

# Memeriksa struktur arsip sebelum ekstraksi
if ! tar -tzf "$ARCHIVE_FILE" >/dev/null 2>&1; then
    gagal "$EXIT_RESTORE" "Arsip rusak atau tidak valid"
fi

# Menolak path absolut dan path traversal sederhana
if ! tar -tzf "$ARCHIVE_FILE" | awk '
{
    if ($0 ~ /^\//) exit 1
    jumlah = split($0, bagian, "/")
    for (i = 1; i <= jumlah; i++) {
        if (bagian[i] == "..") exit 1
    }
}
'; then
    gagal "$EXIT_RESTORE" "Struktur path arsip tidak aman"
fi

# Menentukan nama direktori hasil restore
RESTORE_NAME="${ARCHIVE_NAME%.tar.gz}"
DEST_DIR="$RESTORE_DIR/$RESTORE_NAME"

# Mencegah penimpaan hasil restore sebelumnya
if [ -e "$DEST_DIR" ]; then
    gagal "$EXIT_RESTORE" \
    "Direktori tujuan sudah ada: $DEST_DIR"
fi

# Membuat direktori sementara
STAGING_DIR="$(mktemp -d "$RESTORE_DIR/.restore_tmp.XXXXXX")" || \
    gagal "$EXIT_RESTORE" "Gagal membuat direktori sementara"

# Menghapus direktori sementara jika proses gagal
trap 'if [ -d "${STAGING_DIR:-}" ]; then rm -rf -- "$STAGING_DIR"; fi' EXIT

# Mengekstrak arsip
if ! tar -xzf "$ARCHIVE_FILE" \
    -C "$STAGING_DIR" \
    --no-same-owner \
    --no-same-permissions; then

    gagal "$EXIT_RESTORE" "Ekstraksi arsip gagal"
fi

# Memindahkan hasil ekstraksi ke direktori tujuan
if ! mv "$STAGING_DIR" "$DEST_DIR"; then
    gagal "$EXIT_RESTORE" "Gagal menyimpan hasil restore"
fi

catat_log "SUCCESS" "Restore berhasil"
catat_log "INFO" "Nama arsip: $ARCHIVE_NAME"
catat_log "INFO" "Waktu restore: $(date '+%Y-%m-%d %H:%M:%S')"
catat_log "INFO" "Hasil pemulihan: $DEST_DIR"
catat_log "INFO" "Verifikasi checksum: VALID"

exit "$EXIT_OK"
