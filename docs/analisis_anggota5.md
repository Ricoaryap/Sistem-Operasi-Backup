# Analisis Teori Sistem Operasi — Anggota 5 (Lock, Log, Proteksi, dan Docker)

**Nama:** Bekti Nur Wicaksono (2510512043)

## 1. Critical Section & Sinkronisasi Proses (`flock`)
Proses pengarsipan, penulisan log, dan pembaruan laporan backup merupakan *critical section*. Apabila dua proses backup berjalan bersamaan tanpa sinkronisasi, dapat terjadi *race condition* yang menyebabkan file arsip rusak atau baris laporan saling menimpa. Mekanisme *advisory file locking* dengan `flock -n` pada *file descriptor* (`FD 200`) memastikan hanya satu proses yang boleh masuk ke *critical section* pada satu waktu (*mutual exclusion*). Karena lock dikelola oleh kernel Linux, kunci akan otomatis dilepas ketika proses berakhir atau mengalami *crash*.

## 2. Sistem Berkas & Proteksi Akses Linux
Direktori `/home/operator/project-backup/` diamankan menggunakan kepemilikan grup `backup_group` dan izin akses `2770` (SGID + rwx untuk pemilik dan grup, tanpa akses untuk *others*). Hal ini memastikan hanya user yang berwenang (`user_admin`) yang dapat mengakses hasil backup, sementara `user_biasa` ditolak langsung oleh kernel dengan pesan `Permission denied`.

## 3. Proteksi Bind Mount Read-Only pada Docker
Aktivitas Docker menggunakan opsi `-v /home/operator/project-backup/reports:/mnt/reports:ro`. Flag `:ro` memerintahkan kernel Linux memasang *bind mount* ke dalam *mount namespace* container dengan atribut `MS_RDONLY`. Saat proses di dalam container mencoba menulis atau membuat file melalui *system call* `open()` dengan flag tulis, lapisan **Virtual File System (VFS)** langsung menolaknya dengan kode error `EROFS` (*Read-only file system*). Mekanisme ini menjaga integritas laporan backup di host tetap aman meskipun container hanya diberi peran pembaca laporan.

## 4. Proses & I/O Logging
Setiap aktivitas proses backup dicatat ke `backup.log` beserta timestamp, *Process ID* (`$$`), level log (`INFO`/`ERROR`), dan status akhir (*exit status*) menggunakan pengalihan I/O (`tee` dan *redirection*), sehingga memudahkan audit apabila terjadi kegagalan sistem.
