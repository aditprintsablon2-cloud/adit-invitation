// Isi dari Supabase Dashboard > Project Settings > API
// Gunakan Project URL dan anon/public key. Jangan pernah taruh service_role key di browser.
export const SUPABASE_URL = 'https://faylvcxdxegjymirkvnb.supabase.co';
export const SUPABASE_ANON_KEY = 'sb_publishable_hefFrmOuSGXbtDmT1wFuog__lb6cA2v';

// Email yang ingin ditampilkan sebagai admin oleh UI.
// Hak akses database tetap diamankan oleh role pada tabel profiles + RLS.
export const ADMIN_EMAILS = ['alikuswandi@gmail.com'];

// Bucket dibuat otomatis oleh supabase-setup.sql
export const STORAGE_BUCKET = 'invitation-media';
