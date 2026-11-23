#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_ROOT}/config/paths.env"

if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

BASE_DIR="${BASE_DIR:-/home/operator/project-backup}"
REPORT_DIR="${REPORT_DIR:-${BASE_DIR}/reports}"
REPORT_FILE="${REPORT_DIR}/backup_report.txt"
IMAGE_NAME="alpine:latest"

DOCKER_CMD="docker"
if ! docker info >/dev/null 2>&1; then
    DOCKER_CMD="sudo docker"
fi

if [[ ! -f "$REPORT_FILE" ]]; then
    echo "[INFO] Laporan belum ada, membuat laporan sampel terlebih dahulu..."
    bash "${SCRIPT_DIR}/lock_log_report.sh" 0 "backup_sample_$(date '+%Y%m%d_%H%M%S').tar.gz" "VERIFIED_OK"
fi

echo "================================================================"
echo "UJI POSITIF DOCKER: Membaca laporan melalui bind mount read-only"
echo "================================================================"
$DOCKER_CMD run --rm \
    -v "${REPORT_DIR}:/mnt/reports:ro" \
    "$IMAGE_NAME" \
    cat /mnt/reports/backup_report.txt
POS_EXIT=$?
echo "[RESULT] Exit status uji positif: $POS_EXIT (Harus 0 = Berhasil dibaca)"

echo ""
echo "================================================================"
echo "UJI NEGATIF DOCKER: Menulis/mengubah file di mount read-only"
echo "================================================================"
$DOCKER_CMD run --rm \
    -v "${REPORT_DIR}:/mnt/reports:ro" \
    "$IMAGE_NAME" \
    sh -c 'echo "Percobaan modifikasi ilegal" >> /mnt/reports/backup_report.txt'
NEG_EXIT1=$?
echo "[RESULT] Exit status modifikasi laporan: $NEG_EXIT1 (Harus != 0 = Ditolak)"

$DOCKER_CMD run --rm \
    -v "${REPORT_DIR}:/mnt/reports:ro" \
    "$IMAGE_NAME" \
    touch /mnt/reports/file_baru_ilegal.txt
NEG_EXIT2=$?
echo "[RESULT] Exit status membuat file baru: $NEG_EXIT2 (Harus != 0 = Ditolak)"
