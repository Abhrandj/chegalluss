# CHEGALLUSS CONTROL

Prototipe aplikasi pengawasan operasional peternakan ayam, versi **v1.7**.

## Menjalankan

Buka `index.html` di browser untuk pengujian lokal. Untuk hosting statis, publikasikan isi folder ini melalui GitHub Pages atau Cloudflare Pages.

## Fitur saat ini

- Master kandang dan periode
- Satu form untuk satu bon dengan beberapa item
- Riwayat harga produk dan harga usulan berdasarkan transaksi sebelumnya
- Deposit gabungan distributor, alokasi pembelian per kandang
- Penjualan/panen ke deposit, kas operasional, kasbon
- Laporan Owner dan mode Admin **simulasi**

## PENTING: bukan versi produksi

- Mode Owner/Admin belum autentikasi yang aman.
- Data disimpan lokal di browser, **tidak tersinkron antarperangkat**.
- Jangan masukkan data keuangan asli, data karyawan, dokumen sensitif, atau kredensial.
- Hosting `index.html` secara publik **tidak** otomatis menyediakan login dan basis data aman.
- Sebelum operasional riil: buat backend dan database terpusat, role-based authorization di server, audit log yang tahan manipulasi, dan backup.

## Pengembangan

Gunakan `main` untuk versi stabil dan `develop` untuk perubahan yang sedang diuji.
