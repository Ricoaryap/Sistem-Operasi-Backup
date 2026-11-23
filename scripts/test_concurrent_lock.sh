#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="${SCRIPT_DIR}/lock_log_report.sh"

echo "================================================================"
echo "UJI KONKURENSI: DUA PROSES BACKUP BERJALAN BERSAMAAN (LOCK)"
echo "================================================================"
echo "[1] Menjalankan Proses Backup 1 di background (tahan lock 8 detik)..."
bash "$TARGET_SCRIPT" 8 "backup_proses1_$(date '+%Y%m%d_%H%M%S').tar.gz" "VERIFIED_OK" &
PID1=$!

sleep 2

echo "[2] Menjalankan Proses Backup 2 saat Proses 1 masih memegang lock..."
bash "$TARGET_SCRIPT" 2 "backup_proses2_$(date '+%Y%m%d_%H%M%S').tar.gz" "VERIFIED_OK"
EXIT_PID2=$?

echo "[RESULT] Exit status Proses Backup 2: $EXIT_PID2 (Harus != 0 / Ditolak karena lock aktif)"

wait "$PID1"
EXIT_PID1=$?
echo "[RESULT] Exit status Proses Backup 1: $EXIT_PID1 (Harus 0 / Sukses)"
