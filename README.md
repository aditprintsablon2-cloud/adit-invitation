# Adit Invitation PRO — Multi-user Supabase

Versi ini sudah dimigrasikan dari Firebase ke Supabase. Frontend tetap dapat di-deploy ke Vercel/GitHub, sedangkan Auth, PostgreSQL Database, Storage, RLS, RSVP, buku tamu, dan realtime menggunakan Supabase.

## File penting

- `index.html` — UI aplikasi
- `pro-app.js` — logika aplikasi Supabase
- `supabase-config.js` — Project URL + anon/publishable key
- `supabase-setup.sql` — membuat tabel, trigger, RLS, Storage bucket, Realtime, dan RPC penghitung kunjungan
- `styles-base.css`, `pro.css` — tampilan
- `vercel.json` — konfigurasi Vercel

## 1. Buat project Supabase

1. Buka https://supabase.com dan buat project baru.
2. Tunggu project aktif.
3. Buka **Project Settings > API**.
4. Salin **Project URL**.
5. Salin **anon / publishable key**. Jangan gunakan `service_role` key pada browser.

## 2. Jalankan database setup

1. Buka **SQL Editor > New query**.
2. Copy seluruh isi `supabase-setup.sql`.
3. Klik **Run**.
4. Pastikan tabel `profiles`, `invitations`, `rsvps`, `guestbook`, dan `visits` muncul.
5. Bucket `invitation-media` akan dibuat otomatis.

## 3. Isi konfigurasi aplikasi

Buka `supabase-config.js` lalu isi:

```js
export const SUPABASE_URL = 'https://PROJECT.supabase.co';
export const SUPABASE_ANON_KEY = 'KEY_ANDA';
export const ADMIN_EMAILS = ['email-admin-anda@example.com'];
```

`ADMIN_EMAILS` hanya membantu UI mengenali calon admin. Hak admin sebenarnya tetap ditentukan oleh `profiles.role = 'admin'` di database.

## 4. Authentication

Buka **Authentication > Providers > Email** dan pastikan Email/Password aktif.

Untuk setup awal yang lebih sederhana, Anda dapat menonaktifkan email confirmation sementara. Jika email confirmation aktif, user harus membuka email konfirmasi sebelum bisa login.

## 5. Membuat admin pertama

1. Deploy aplikasi atau jalankan lokal.
2. Daftar memakai email admin.
3. Setelah akun muncul di tabel `profiles`, buka SQL Editor dan jalankan:

```sql
update public.profiles
set role = 'admin'
where email = 'email-admin-anda@example.com';
```

4. Logout lalu login kembali.

## 6. Deploy ke GitHub + Vercel

Upload semua file project ke root repository GitHub. Di Vercel:

- Framework Preset: `Other`
- Root Directory: `.`
- Build Command: kosong
- Output Directory: `.`

Klik **Deploy**.

## 7. Site URL Supabase

Buka **Authentication > URL Configuration**.

Isi **Site URL** dengan domain Vercel Anda, misalnya:

`https://adit-invitation-pro.vercel.app`

Tambahkan domain yang sama ke Redirect URLs jika diperlukan.

## 8. Pengujian wajib

- Registrasi user baru
- Login/logout
- User A tidak melihat data User B
- Admin dapat melihat user dan semua undangan
- Buat/edit/simpan undangan
- Upload cover, galeri, QRIS, musik
- Publish undangan
- Link publik `?i=UUID` dapat dibuka tanpa login
- RSVP berhasil
- Buku tamu berhasil
- Statistik kunjungan bertambah
- Realtime RSVP/buku tamu bekerja

## Struktur data

`invitations` menyimpan metadata utama di kolom biasa dan seluruh data desain undangan pada kolom `data` bertipe JSONB. Ini membuat fitur editor mudah dikembangkan tanpa harus menambah kolom untuk setiap pengaturan baru.

## Keamanan

Aplikasi menggunakan Row Level Security (RLS). User biasa hanya dapat mengelola undangan miliknya. Admin ditentukan dari `profiles.role`. Link publik hanya dapat membaca undangan yang `published = true`, `active = true`, dan belum melewati `active_until`.

Jangan pernah menaruh Supabase `service_role` key di `supabase-config.js`, GitHub frontend, atau JavaScript browser.
