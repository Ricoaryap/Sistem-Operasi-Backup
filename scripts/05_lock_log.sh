#!/usr/bin/env bash
# ==============================================================================
# 05_lock_log.sh - Modul Integrasi Utama, Lock (flock), Log, & Laporan Backup 5A
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 1. Muat konfigurasi paths.env dan modul fungsi lock_log_report.sh milik Bekti
source "${PROJECT_ROOT}/config/paths.env"
source "${SCRIPT_DIR}/lock_log_report.sh"

mkdir -p "$SOURCE_DIR" "$ARCHIVE_DIR" "$RESTORE_DIR" "$OUTPUT_DIR" "$LOG_DIR" "$REPORT_DIR"

# Fungsi sinkronisasi laporan agar tersedia di reports/backup_report.txt DAN output/laporan.txt
sync_laporan_output() {
    if [[ -f "$REPORT_FILE" ]]; then
        cp "$REPORT_FILE" "$OUTPUT_DIR/laporan.txt"
    fi
}

echo "=========================================================================="
echo "      SISTEM OTOMASI BACKUP & PEMULIHAN DATA LINUX (INTEGRASI 5A)         "
echo "=========================================================================="

# --- TAHAP 0: AKUISISI LOCK ---
if ! acquire_lock; then
    exit 1
fi
trap release_lock EXIT

# --- TAHAP 1: VALIDASI SUMBER & PARAMETER ---
write_log "INFO" "[1/4] Menjalankan validasi sumber ($SOURCE_DIR) dan tujuan ($ARCHIVE_DIR)..."
bash "${SCRIPT_DIR}/01_validate.sh" "$SOURCE_DIR" "$ARCHIVE_DIR"
STATUS_1=$?
if [[ $STATUS_1 -ne 0 ]]; then
    write_log "ERROR" "Tahap 1 (Validasi Sumber) GAGAL dengan exit status $STATUS_1."
    generate_report "TIDAK_ADA_ARSIP" "FAILED_VALIDATE(Exit:$STATUS_1)"
    sync_laporan_output
    exit $STATUS_1
fi

# --- TAHAP 2: PEMBUATAN ARSIP .tar.gz & .sha256 ---
write_log "INFO" "[2/4] Menjalankan pembuatan arsip backup..."
bash "${SCRIPT_DIR}/02_backup.sh"
STATUS_2=$?
if [[ $STATUS_2 -ne 0 ]]; then
    write_log "ERROR" "Tahap 2 (Pembuatan Arsip) GAGAL dengan exit status $STATUS_2."
    generate_report "GAGAL_BUAT_ARSIP" "FAILED_BACKUP(Exit:$STATUS_2)"
    sync_laporan_output
    exit $STATUS_2
fi

# Ambil file arsip .tar.gz paling baru yang baru saja dibuat oleh 02_backup.sh
ARSIP_TERBARU="$(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name 'backup_*.tar.gz' -printf '%T@ %p\n' | sort -nr | head -n 1 | cut -d' ' -f2-)"
NAMA_ARSIP="$(basename "$ARSIP_TERBARU")"

# --- TAHAP 3: VERIFIKASI INTEGRITAS SHA256SUM ---
write_log "INFO" "[3/4] Menjalankan verifikasi integritas untuk $NAMA_ARSIP..."
bash "${SCRIPT_DIR}/03_verify.sh" "$NAMA_ARSIP"
STATUS_3=$?
if [[ $STATUS_3 -ne 0 ]]; then
    write_log "ERROR" "Tahap 3 (Verifikasi Integritas) GAGAL dengan exit status $STATUS_3."
    generate_report "$NAMA_ARSIP" "FAILED_VERIFY(Exit:$STATUS_3)"
    sync_laporan_output
    exit $STATUS_3
fi

# --- TAHAP 4: PEMULIHAN DATA / RESTORE KE DIREKTORI UJI ---
write_log "INFO" "[4/4] Menjalankan uji pemulihan data (restore) untuk $ARSIP_TERBARU..."
bash "${SCRIPT_DIR}/04_restore.sh" "$ARSIP_TERBARU"
STATUS_4=$?
if [[ $STATUS_4 -ne 0 ]]; then
    write_log "ERROR" "Tahap 4 (Pemulihan Data) GAGAL dengan exit status $STATUS_4."
    generate_report "$NAMA_ARSIP" "FAILED_RESTORE(Exit:$STATUS_4)"
    sync_laporan_output
    exit $STATUS_4
fi

# --- TAHAP 5: PENCATATAN LAPORAN AKHIR ---
generate_report "$NAMA_ARSIP" "VERIFIED_&_RESTORED_OK"
sync_laporan_output
write_log "INFO" "Seluruh rangkaian integrasi (Validasi -> Backup -> Verify -> Restore -> Laporan) SELESAI!"
echo "=========================================================================="
echo "[SUCCESS] Integrasi selesai! Laporan tersedia di:"
echo "  1. $REPORT_FILE"
echo "  2. $OUTPUT_DIR/laporan.txt"
echo "=========================================================================="
exit 0
