# Adit Invitation PRO — Multi-user Firebase

Aplikasi web pembuat undangan digital multi-user untuk Adit Print. Frontend dapat di-deploy ke Vercel; autentikasi, database realtime, dan penyimpanan file menggunakan Firebase.

## Fitur

- Login dan registrasi pelanggan dengan Firebase Authentication
- Role `user` dan `admin`
- Dashboard multi-user; pelanggan hanya melihat undangannya sendiri
- Admin melihat seluruh undangan dan daftar pelanggan
- Admin dapat mengubah role, paket, status pengguna, paket undangan, masa aktif, publish/unpublish
- Editor undangan realtime dengan 4 template
- Cover, galeri, QRIS, dan musik tersimpan di Firebase Storage
- RSVP dan buku tamu di Cloud Firestore
- Statistik hadir/tidak hadir, jumlah ucapan, dan jumlah kunjungan
- Link publik per undangan dan personalisasi nama tamu melalui parameter `to`
- Countdown, Google Maps, WhatsApp, amplop digital, QRIS, musik
- Draft / Published / Nonaktif
- Siap deploy ke Vercel

## 1. Buat Project Firebase

1. Buka Firebase Console dan klik **Create a project**.
2. Tambahkan **Web App**.
3. Salin object `firebaseConfig` yang diberikan Firebase.
4. Aktifkan **Authentication > Sign-in method > Email/Password**.
5. Buat **Cloud Firestore**.
6. Aktifkan **Firebase Storage**.

## 2. Isi firebase-config.js

Buka `firebase-config.js`, lalu ganti seluruh placeholder dengan konfigurasi Web App dari Firebase. Gunakan nilai `storageBucket` persis seperti yang diberikan Firebase Console.

Contoh struktur:

```js
export const firebaseConfig = {
  apiKey: "...",
  authDomain: "project.firebaseapp.com",
  projectId: "project",
  storageBucket: "...",
  messagingSenderId: "...",
  appId: "..."
};
```

`ADMIN_EMAILS` boleh diisi email admin Adit Print. Ini membantu UI mengenali admin saat pertama kali login, tetapi keamanan utama tetap ditentukan oleh field `role` pada Firestore + Security Rules.

## 3. Pasang Firestore Rules

Firebase Console > Firestore Database > Rules. Hapus rules lama, tempel seluruh isi `firestore.rules`, lalu **Publish**.

Rules ini membuat:
- pelanggan hanya dapat mengelola undangan miliknya;
- admin dapat mengelola semua data;
- undangan publik hanya dapat dibaca jika `published=true`;
- tamu dapat mengirim RSVP/ucapan hanya ke undangan yang published.

## 4. Pasang Storage Rules

Firebase Console > Storage > Rules. Tempel isi `storage.rules`, lalu **Publish**.

Aset undangan dibuat public-readable karena foto/musik/QRIS memang harus dapat tampil pada halaman undangan publik. Upload hanya diizinkan kepada pemilik proyek atau admin, maksimal 15 MB per file.

## 5. Buat Admin Pertama

Cara aman dan mudah:

1. Jalankan aplikasi setelah Firebase tersambung.
2. Daftarkan akun admin melalui form registrasi (awalnya role `user`).
3. Buka Firestore > collection `users` > dokumen UID akun tadi.
4. Ubah field `role` dari `user` menjadi `admin`.
5. Logout lalu login ulang.

Setelah itu menu statistik global dan **Manajemen Pelanggan** akan muncul.

> Jangan membuat fitur pendaftaran publik yang boleh menentukan role `admin`. Security Rules proyek ini memaksa akun baru yang membuat dokumen profil sendiri memakai role `user`.

## 6. Struktur Firestore

```text
users/{uid}
  name
  email
  role: user | admin
  plan: Basic | Pro | Premium
  active: true | false

invitations/{invitationId}
  ownerId
  ownerEmail
  projectName
  slug
  published
  active
  activeUntil
  plan
  cover
  gallery[]
  music
  qris
  visitCount
  ...isi/desain undangan

invitations/{invitationId}/rsvps/{id}
invitations/{invitationId}/guestbook/{id}
invitations/{invitationId}/visits/{id}
```

## 7. Link Undangan

Aplikasi memakai query parameter sehingga tidak membutuhkan rewrite khusus:

```text
https://domain-anda.vercel.app/?i=ID_UNDANGAN
https://domain-anda.vercel.app/?i=ID_UNDANGAN&to=Bapak%20Ahmad%20%26%20Keluarga
```

Slug juga dapat digunakan saat query Firestore mengizinkannya, tetapi dashboard secara default menghasilkan link memakai document ID agar unik dan stabil.

## 8. Deploy ke Vercel lewat GitHub

1. Buat repository GitHub baru.
2. Upload semua file dalam folder ini ke root repository.
3. Login ke Vercel > **Add New Project**.
4. Import repository tersebut.
5. Framework Preset: **Other**.
6. Build Command: kosong.
7. Output Directory: `.`
8. Deploy.

Setelah mengubah Firebase Rules, `firebase-config.js`, atau aplikasi, push perubahan ke GitHub. Vercel akan deploy ulang otomatis.

## Catatan Produksi

- Sebelum dijual ke pelanggan, gunakan domain sendiri dan ganti email admin contoh.
- Sebaiknya aktifkan Firebase App Check untuk mengurangi penyalahgunaan API dari luar website.
- Batasi ukuran foto sebelum upload agar biaya Storage/Bandwidth lebih rendah.
- Untuk paket berbayar otomatis, integrasikan payment gateway pada tahap berikutnya; versi ini menyediakan kontrol paket oleh admin tetapi belum memproses pembayaran otomatis.
- Firebase mengenakan biaya berdasarkan penggunaan di luar kuota gratis, jadi pantau dashboard Usage & Billing.

## File Penting

- `index.html` — UI login, dashboard, editor, dan undangan publik
- `pro-app.js` — Firebase Auth/Firestore/Storage + seluruh logika PRO
- `firebase-config.js` — konfigurasi Firebase Anda
- `styles-base.css` — gaya undangan/editor dasar
- `pro.css` — gaya dashboard/login/admin
- `firestore.rules` — security rules database
- `storage.rules` — security rules file
- `vercel.json` — konfigurasi deploy Vercel
