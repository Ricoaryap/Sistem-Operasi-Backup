# Dokumentasi Pengujian Anggota 5 — Lock, Log, Laporan, dan Docker

**Nama:** Bekti Nur Wicaksono (2510512043)  
**Tanggung Jawab:** Lock, Log, Laporan Backup, Pembatasan Akses, dan Docker Bind Mount Read-Only

| No | Skenario Pengujian | Jenis | Perintah Uji | Hasil yang Diharapkan | Bukti (`evidence/`) |
|----|--------------------|-------|--------------|------------------------|---------------------|
| 1 | Akses folder backup oleh `user_admin` (`backup_group`) | Positif | `sudo -u user_admin ls -la /home/operator/project-backup/archive/` | Akses diizinkan (`exit 0`). | `anggota5_setup_env.log` |
| 2 | Akses folder backup oleh `user_biasa` (non-group) | Negatif | `sudo -u user_biasa ls -la /home/operator/project-backup/archive/` | Akses ditolak (`Permission denied`, `exit != 0`). | `anggota5_setup_env.log` |
| 3 | Dua proses backup berjalan bersamaan | Negatif (Konkurensi) | `./scripts/test_concurrent_lock.sh` | Proses 1 mendapat lock (`exit 0`), Proses 2 ditolak (`exit 1`) dan tercatat di log. | `anggota5_concurrent_lock.log` |
| 4 | Pencatatan log & pembuatan laporan backup | Positif | `./scripts/lock_log_report.sh` | Terbentuk `backup.log` dan `backup_report.txt` berisi waktu, nama arsip, dan status verifikasi. | `anggota5_backup_report.txt` |
| 5 | Container Docker membaca laporan melalui mount `:ro` | Positif (Docker) | `docker run --rm -v /home/operator/project-backup/reports:/mnt/reports:ro alpine:latest cat /mnt/reports/backup_report.txt` | Isi laporan terbaca di stdout container (`exit 0`). | `anggota5_docker_ro_test.log` |
| 6 | Container Docker menulis/mengubah file pada mount `:ro` | Negatif (Docker) | `docker run --rm -v /home/operator/project-backup/reports:/mnt/reports:ro alpine:latest touch /mnt/reports/file_baru_ilegal.txt` | Penulisan ditolak dengan error `Read-only file system` (`exit != 0`). | `anggota5_docker_ro_test.log` |
