# Contributing to EasyR

Terima kasih telah berkontribusi ke EasyR.

## Menambahkan Modul Statistik Baru

Setiap modul baru mengikuti pola folder:

```text
modules/<nama-modul>/
  schema.json
  template.R
```

Langkah minimum:

1. Buat folder baru di `modules/<nama-modul>/`.
2. Tambahkan `schema.json` untuk mendefinisikan field input, validasi, dan output UI.
3. Tambahkan `template.R` untuk membentuk script analisis dari parameter yang diterima.
4. Pastikan nama parameter di `schema.json` selaras dengan variabel yang dipakai di `template.R`.

## Menjalankan Pengujian Modul

Setelah menambah atau mengubah modul, jalankan verifikasi berikut:

```bash
Rscript tests/verify_all_modules.R
```

Script ini memeriksa konsistensi struktur modul dan memastikan modul dapat diproses sesuai kontrak engine.

## Development Workflow

```bash
npm install
npm run typecheck
npm run build
```

Gunakan command di atas sebelum membuat pull request untuk mengurangi gagal CI.

## Pull Request Checklist

- Modul baru memiliki pasangan `schema.json` dan `template.R`.
- Validasi modul lulus dengan `Rscript tests/verify_all_modules.R`.
- Type checking dan build lulus.
- Dokumentasi relevan ikut diperbarui jika ada perubahan behavior.
