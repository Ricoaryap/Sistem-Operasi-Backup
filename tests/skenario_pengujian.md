# Dokumentasi Skenario Pengujian Positif (+), Negatif (-), & Data Dummy

Dokumen ini memuat spesifikasi pembangkitan data *dummy*, matriks skenario pengujian kondisi positif (+) dan negatif (-) untuk seluruh anggota kelompok, pengujian integrasi penuh, pengujian beban CPU/memori, serta prosedur pemulihan kondisi uji.

---

## 1. Persiapan Direktori dan Data Dummy Pengujian

Sesuai ketentuan proyek, seluruh pengujian menggunakan data *dummy* di dalam direktori khusus proyek agar tidak melibatkan data pribadi maupun sistem utama host.

```bash
# 1. Menyiapkan struktur direktori operasional
mkdir -p source archive restore output logs reports

# 2. Membuat berkas data dummy teks untuk pengujian fungsional (KU-01 s/d KU-05)
echo "Dokumen operasional utama unit kerja Kelompok 3" > source/dokumen_utama.txt
echo "Data rekapitulasi praktikum sistem operasi 2026" > source/data_tambahan.txt

# 3. Memberikan izin eksekusi pada seluruh script
chmod +x scripts/*.sh
```

---

## 2. Matriks Ringkasan Skenario Pengujian Kelompok 3

| ID Uji | Penanggung Jawab | Skenario Pengujian | Jenis | Perintah Uji Utama | Hasil yang Diharapkan & Exit Status | Bukti (`evidence/`) |
| :---: | :--- | :--- | :---: | :--- | :--- | :--- |
| **KU-01A** | **Najwa Aulia**<br>(2510512129) | Validasi direktori sumber yang tersedia dan berisi berkas | **Positif (+)** | `./scripts/01_validate.sh source archive` | Direktori sumber dinyatakan valid (`exit 0`) | `evidence_01_validate.png` |
| **KU-01B** | **Najwa Aulia**<br>(2510512129) | Validasi direktori sumber yang tidak ditemukan / kosong | **Negatif (-)** | `./scripts/01_validate.sh folder_tidak_ada archive` | Ditolak dengan pesan `[ERROR] Sumber tidak ditemukan` (`exit 2`) | `evidence_01_validate.png` |
| **KU-02A** | **Rico Sandika A.**<br>(2510512053) | Pembuatan arsip `.tar.gz` ber-timestamp & file `.sha256` | **Positif (+)** | `./scripts/02_backup.sh` | Arsip `.tar.gz` dan checksum `.sha256` terbentuk di `archive/` (`exit 0`) | `evidence_02_backup.png` |
| **KU-02B** | **Rico Sandika A.**<br>(2510512053) | Pembuatan arsip saat direktori tujuan `archive/` *read-only* | **Negatif (-)** | `chmod -w archive/ && ./scripts/02_backup.sh` | Gagal tulis & muncul pesan `[ERROR] Direktori tujuan tidak dapat ditulis` (`exit 3`) | `evidence_02_backup.png` |
| **KU-03A** | **Kenzia Zahwa E.**<br>(2510512121) | Verifikasi integritas `sha256sum` pada arsip asli | **Positif (+)** | `bash scripts/03_verify.sh` | Checksum cocok (`OK`) dan integritas terverifikasi (`exit 0`) | `evidence_03_verify.png` |
| **KU-03B** | **Kenzia Zahwa E.**<br>(2510512121) | Verifikasi integritas pada salinan arsip yang dimodifikasi | **Negatif (-)** | `echo "Data diubah" >> archive/backup_test.tar.gz && bash scripts/03_verify.sh backup_test.tar.gz` | Terdeteksi `FAILED` (*checksum did NOT match*) (`exit 4`) | `evidence_03_verify.png` |
| **KU-04A** | **Vrista Darin N.**<br>(2510512119) | Pemulihan data (*restore*) dari arsip valid & uji `diff -qr` | **Positif (+)** | `bash scripts/04_restore.sh archive/<arsip_valid.tar.gz>` | Data pulih ke `restore/` dan hasil `diff -qr` identik (`exit 0`) | `evidence_04_restore_positive.png`<br>`evidence_04_restore_verification.png` |
| **KU-04B** | **Vrista Darin N.**<br>(2510512119) | Pemulihan data dari arsip rusak / gagal checksum | **Negatif (-)** | `bash scripts/04_restore.sh archive/backup_rusak.tar.gz` | Ditolak sebelum ekstraksi dengan log `Verifikasi checksum gagal` (`exit 5`) | `evidence_04_restore_negative.png` |
| **KU-05A** | **Bekti Nur W.**<br>(2510512043) | Akuisisi lock `flock`, pencatatan laporan, & akses `user_admin` | **Positif (+)** | `bash scripts/lock_log_report.sh` & `sudo -u user_admin ls -la archive/` | Lock berhasil diperoleh, laporan tercatat, dan `user_admin` diizinkan (`exit 0`) | `evidence_05_log_report.png`<br>`evidence_05_setup_env.png` |
| **KU-05B** | **Bekti Nur W.**<br>(2510512043) | Eksekusi 2 proses backup bersamaan & akses `user_biasa` | **Negatif (-)** | `./scripts/test_concurrent_lock.sh` & `sudo -u user_biasa ls -la archive/` | Proses ke-2 ditolak lock (`exit 1`) dan `user_biasa` ditolak `Permission denied` (`exit 2`) | `evidence_05_concurrent_lock.png`<br>`evidence_05_setup_env.png` |
| **KU-05C** | **Bekti & Rico** | Container Docker `alpine:3.20` membaca `output/laporan.txt` via mount `readonly` | **Positif (+)** | `sudo docker run --rm --mount type=bind,src="$(pwd)/output",dst=/data,readonly alpine:3.20 cat /data/laporan.txt` | Isi laporan tampil di terminal melalui container (`exit 0`) | `evidence_05_docker_ro.png`<br>`evidence_docker_checksum_h7.png` |
| **KU-05D** | **Bekti & Rico** | Container Docker mencoba menulis ke mount `readonly` | **Negatif (-)** | `sudo docker run --rm --mount type=bind,src="$(pwd)/output",dst=/data,readonly alpine:3.20 sh -c 'echo "uji" >> /data/laporan.txt'` | Ditolak dengan `Read-only file system` (`exit 1`) & checksum `sha256sum` host tetap | `evidence_05_docker_ro.png`<br>`evidence_docker_checksum_h7.png` |
| **INT-01** | **Kelompok 3** | Eksekusi integrasi penuh 5 modul (`01` s/d `05`) | **Integrasi** | `bash scripts/05_lock_log.sh` | Seluruh modul berjalan berurutan dan memperbarui `output/laporan.txt` (`exit 0`) | `evidence_integrasi_h7.png` |
| **LOAD-01** | **Kelompok 3** | Pengamatan CPU & Memori pada 2 ukuran beban uji (1 MB vs 20 MB) | **Beban Uji** | `/usr/bin/time -f "..." bash scripts/02_backup.sh` | Beban 1MB (`0:00.03`, CPU `90%`, RSS `3584 KB`) vs 20MB (`0:00.15`, CPU `94%`, RSS `3712 KB`) | `evidence_beban_cpu_memori_h7.png` |

---

## 3. Rincian Langkah Reproduksi Pengujian Per Kasus Uji

### 3.1 Kasus Uji KU-01: Validasi Sumber dan Parameter (`01_validate.sh`)
```bash
# Kondisi Positif (+): Sumber valid
./scripts/01_validate.sh source archive
echo $?   # Hasil yang diharapkan: 0

# Kondisi Negatif (-): Sumber tidak tersedia
./scripts/01_validate.sh folder_tidak_ada archive
echo $?   # Hasil yang diharapkan: 2
```

### 3.2 Kasus Uji KU-02: Pembuatan Arsip Backup (`02_backup.sh`)
```bash
# Kondisi Positif (+): Direktori tujuan writable
./scripts/02_backup.sh
echo $?   # Hasil yang diharapkan: 0
ls -lh archive/

# Kondisi Negatif (-): Direktori tujuan read-only
chmod -w archive/
./scripts/02_backup.sh
echo $?   # Hasil yang diharapkan: 3

# Pemulihan izin direktori
chmod +w archive/
```

### 3.3 Kasus Uji KU-03: Verifikasi Integritas (`03_verify.sh`)
```bash
# Kondisi Positif (+): Arsip asli
bash scripts/03_verify.sh
echo $?   # Hasil yang diharapkan: 0

# Kondisi Negatif (-): Arsip mengalami modifikasi
echo "Data telah dimodifikasi." >> archive/backup_test.tar.gz
bash scripts/03_verify.sh backup_test.tar.gz
echo $?   # Hasil yang diharapkan: 4
```

### 3.4 Kasus Uji KU-04: Pemulihan Data / Restore (`04_restore.sh`)
```bash
# Kondisi Positif (+): Pemulihan dari arsip valid & verifikasi diff
cp archive/backup_20261123_194607.tar.gz archive/backup_bukti.tar.gz
cp archive/backup_20261123_194607.tar.gz.sha256 archive/backup_bukti.tar.gz.sha256
bash scripts/04_restore.sh archive/backup_bukti.tar.gz
echo $?   # Hasil yang diharapkan: 0
diff -qr source/ restore/backup_bukti/
echo $?   # Hasil yang diharapkan: 0 (Identik)

# Kondisi Negatif (-): Pemulihan dari arsip rusak
cp archive/backup_20261123_194607.tar.gz archive/backup_rusak_bukti.tar.gz
(cd archive && sha256sum backup_rusak_bukti.tar.gz > backup_rusak_bukti.tar.gz.sha256)
echo "DATA RUSAK" >> archive/backup_rusak_bukti.tar.gz
bash scripts/04_restore.sh archive/backup_rusak_bukti.tar.gz
echo $?   # Hasil yang diharapkan: 5
```

### 3.5 Kasus Uji KU-05: Lock Konkurensi, Laporan, dan Docker Read-Only
```bash
# 1. Uji Konkurensi 2 Proses Backup Bersamaan
bash scripts/test_concurrent_lock.sh

# 2. Uji Integrasi Penuh 5 Modul
bash scripts/05_lock_log.sh
echo $?   # Hasil yang diharapkan: 0

# 3. Uji Docker Bind Mount Read-Only + Verifikasi Checksum Host
sha256sum output/laporan.txt
sudo docker run --rm --mount type=bind,src="$(pwd)/output",dst=/data,readonly alpine:3.20 cat /data/laporan.txt
echo $?   # Hasil yang diharapkan: 0
sudo docker run --rm --mount type=bind,src="$(pwd)/output",dst=/data,readonly alpine:3.20 sh -c 'echo "uji" >> /data/laporan.txt'
echo $?   # Hasil yang diharapkan: 1
sha256sum output/laporan.txt
```

### 3.6 Pengujian Beban CPU dan Memori (1 MB vs 20 MB)
```bash
# Beban Uji 1 (Kecil: 1 MB)
dd if=/dev/zero of=source/beban_uji.bin bs=1M count=1 2>/dev/null
/usr/bin/time -f "Beban 1MB -> Waktu: %E | CPU: %P | Memori Maks (RSS): %M KB" bash scripts/02_backup.sh

# Beban Uji 2 (Sedang: 20 MB)
dd if=/dev/zero of=source/beban_uji.bin bs=1M count=20 2>/dev/null
/usr/bin/time -f "Beban 20MB -> Waktu: %E | CPU: %P | Memori Maks (RSS): %M KB" bash scripts/02_backup.sh

# Pembersihan berkas beban uji
rm -f source/beban_uji.bin
```

---

## 4. Prosedur Pembersihan dan Pemulihan Kondisi Uji (Recovery)

Untuk mengembalikan kondisi direktori kerja ke keadaan bersih setelah seluruh skenario negatif selesai dijalankan:
```bash
chmod +w archive/ restore/ source/ 2>/dev/null || true
rm -f source/beban_uji.bin archive/backup_test.tar.gz* archive/backup_rusak*.tar.gz* archive/backup_bukti.tar.gz*
rm -rf restore/* /tmp/backup_5a.lock
```
