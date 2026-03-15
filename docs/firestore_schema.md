# Firestore Schema Design - Lawhi

This schema is optimized for the **Firebase Free Tier**, minimizing document reads and writes.

## 1. Collection: `users`
Stores user settings and profile data.

- **Document ID**: `uid` (from Firebase Auth)
- **Fields**:
    - `display_name`: string
    - `email`: string
    - `preferred_language`: string ("ar" | "fr")
    - `settings`: map
        - `font_size`: number (default: 18)
        - `theme`: string ("light" | "dark" | "pastel_green" | etc.)
        - `auto_scroll_speed`: string ("slow" | "medium" | "fast")
        - `last_updated`: timestamp

## 2. Collection: `user_sites`
Stores the 4 markers (hifz, muraja'a, tilawa, browsing) for each user.

- **Document ID**: `uid` (One document per user to save reads, or 4 documents if frequent updates)
- **Fields**:
    - `uid`: string (index)
    - `sites`: map
        - `hifz`: map
            - `surah_id`: number
            - `thumn_id`: number
            - `ayah_index`: number
            - `updated_at`: timestamp
        - `muraja_a`: map (same structure)
        - `tilawa`: map (same structure)
        - `browsing`: map (same structure)

## 3. Collection: `quran_meta` (Optional/Cache)
Static data if not fully loaded from API.

- **Document ID**: `surah_{id}`
- **Fields**:
    - `name_ar`: string
    - `name_fr`: string
    - `total_ayahs`: number
    - `thumn_mapping`: array (Mapping which ayahs belong to which Thumn)

---

## Firestore Security Rules (Draft)

```javascript
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own profile and sites
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /user_sites/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    // Quran metadata is public but read-only
    match /quran_meta/{document=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```
