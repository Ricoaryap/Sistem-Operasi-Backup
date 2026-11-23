#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_ROOT}/config/paths.env"

if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

BASE_DIR="${BASE_DIR:-/home/operator/project-backup}"
LOG_DIR="${LOG_DIR:-${BASE_DIR}/logs}"
REPORT_DIR="${REPORT_DIR:-${BASE_DIR}/reports}"
LOCK_FILE="${LOCK_FILE:-${BASE_DIR}/backup.lock}"

LOG_FILE="${LOG_DIR}/backup.log"
REPORT_FILE="${REPORT_DIR}/backup_report.txt"

mkdir -p "$LOG_DIR" "$REPORT_DIR" "$(dirname "$LOCK_FILE")"

write_log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [PID:$$] [$level] $message" | tee -a "$LOG_FILE"
}

acquire_lock() {
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
        write_log "ERROR" "GAGAL memperoleh lock ($LOCK_FILE). Proses backup lain sedang berjalan!"
        return 1
    fi
    echo "$$" >&200
    write_log "INFO" "Lock berhasil diperoleh pada $LOCK_FILE (PID: $$)."
    return 0
}

release_lock() {
    flock -u 200 2>/dev/null || true
    write_log "INFO" "Lock dilepaskan oleh PID: $$."
}

generate_report() {
    local archive_name="$1"
    local verify_status="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    if [[ ! -f "$REPORT_FILE" ]]; then
        {
            echo "=========================================================================="
            echo "                  LAPORAN OTOMASI BACKUP & VERIFIKASI                     "
            echo "=========================================================================="
            printf "%-20s | %-30s | %-18s\n" "WAKTU" "NAMA ARSIP" "HASIL VERIFIKASI"
            echo "--------------------------------------------------------------------------"
        } > "$REPORT_FILE"
    fi

    printf "%-20s | %-30s | %-18s\n" "$timestamp" "$archive_name" "$verify_status" >> "$REPORT_FILE"
    chmod 640 "$REPORT_FILE" 2>/dev/null || true
    write_log "INFO" "Laporan diperbarui di $REPORT_FILE (Arsip=$archive_name, Status=$verify_status)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SIMULATE_SECONDS="${1:-0}"
    ARCHIVE_NAME="${2:-backup_$(date '+%Y%m%d_%H%M%S').tar.gz}"
    VERIFY_STATUS="${3:-OK (SHA256 MATCH)}"

    if ! acquire_lock; then
        exit 1
    fi
    trap release_lock EXIT

    write_log "INFO" "Memulai proses backup simulasi (durasi: ${SIMULATE_SECONDS}s)..."
    if (( SIMULATE_SECONDS > 0 )); then
        sleep "$SIMULATE_SECONDS"
    fi

    generate_report "$ARCHIVE_NAME" "$VERIFY_STATUS"
    write_log "INFO" "Proses backup selesai dengan sukses."
    exit 0
fi
