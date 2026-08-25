// Isi dari Firebase Console > Project settings > Your apps > Web app
export const firebaseConfig = {
  apiKey: "GANTI_DENGAN_API_KEY",
  authDomain: "GANTI_DENGAN_PROJECT_ID.firebaseapp.com",
  projectId: "GANTI_DENGAN_PROJECT_ID",
  storageBucket: "GANTI_DENGAN_PROJECT_ID.firebasestorage.app",
  messagingSenderId: "GANTI_DENGAN_MESSAGING_SENDER_ID",
  appId: "GANTI_DENGAN_APP_ID"
};

// Email ini otomatis dianggap admin oleh UI. Tetap amankan Firestore dengan role=admin.
export const ADMIN_EMAILS = ["admin@aditprint.local"];
