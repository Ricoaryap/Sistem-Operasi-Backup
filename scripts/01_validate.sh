#!/bin/bash
# validasi.sh - Validasi parameter dan direktori sumber backup
# Pembuat    : Najwa Aulia (2510512129) - Validasi Sumber & Parameter
# Penggunaan : ./validasi.sh <direktori_sumber> <direktori_tujuan>
# Exit status: 0 = valid, 1 = parameter salah/tujuan bukan direktori,
#              2 = sumber tidak valid (tidak ada, bukan direktori, tidak terbaca, kosong)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"
LOG_DIR="${LOG_DIR:-$PROJECT_DIR/logs}"
LOG_FILE="$LOG_DIR/validasi.log"

EXIT_OK=0
EXIT_PARAM=1
EXIT_SUMBER=2

catat_log() {
    local level="$1" pesan="$2" baris
    baris="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [PID $$] $pesan"
    if [ "$level" = "ERROR" ]; then
        echo "$baris" >&2
    else
        echo "$baris"
    fi
    mkdir -p "$LOG_DIR" 2>/dev/null
    { echo "$baris" >> "$LOG_FILE"; } 2>/dev/null
}

if [ "$#" -ne 2 ]; then
    catat_log "ERROR" "Parameter salah. Penggunaan: $0 <direktori_sumber> <direktori_tujuan>"
    exit $EXIT_PARAM
fi

SUMBER="$1"
TUJUAN="$2"

if [ -z "$SUMBER" ] || [ -z "$TUJUAN" ]; then
    catat_log "ERROR" "Parameter sumber atau tujuan tidak boleh kosong"
    exit $EXIT_PARAM
fi

if [ ! -e "$SUMBER" ]; then
    catat_log "ERROR" "Sumber tidak ditemukan: $SUMBER"
    exit $EXIT_SUMBER
fi

if [ ! -d "$SUMBER" ]; then
    catat_log "ERROR" "Sumber bukan direktori: $SUMBER"
    exit $EXIT_SUMBER
fi

if [ ! -r "$SUMBER" ] || [ ! -x "$SUMBER" ]; then
    catat_log "ERROR" "Sumber tidak dapat dibaca/diakses oleh user '$(whoami)': $SUMBER"
    exit $EXIT_SUMBER
fi

JUMLAH_FILE=0
TIDAK_TERBACA=0

while IFS= read -r -d '' berkas; do
    JUMLAH_FILE=$((JUMLAH_FILE + 1))
    if [ ! -r "$berkas" ]; then
        TIDAK_TERBACA=$((TIDAK_TERBACA + 1))
        catat_log "WARN" "Berkas tidak dapat dibaca: $berkas"
    fi
done < <(find "$SUMBER" -type f -print0 2>/dev/null)

if [ "$JUMLAH_FILE" -eq 0 ]; then
    catat_log "ERROR" "Sumber kosong (tidak ada berkas): $SUMBER"
    exit $EXIT_SUMBER
fi

if [ "$TIDAK_TERBACA" -gt 0 ]; then
    catat_log "ERROR" "$TIDAK_TERBACA berkas di sumber tidak dapat dibaca"
    exit $EXIT_SUMBER
fi

if [ -e "$TUJUAN" ] && [ ! -d "$TUJUAN" ]; then
    catat_log "ERROR" "Tujuan sudah ada tetapi bukan direktori: $TUJUAN"
    exit $EXIT_PARAM
fi

if [ ! -e "$TUJUAN" ]; then
    catat_log "INFO" "Tujuan belum ada, akan dibuat oleh script pengarsipan: $TUJUAN"
fi

catat_log "INFO" "VALID: sumber '$SUMBER' ($JUMLAH_FILE berkas), tujuan '$TUJUAN'"
exit $EXIT_OK
