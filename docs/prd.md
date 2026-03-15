# PRD - Lawhi (لوحي)

## 1. Product Overview
**Lawhi (لوحي)** is a mobile/tablet application dedicated to Quran reading and memorization (Hifz), specifically designed around the traditional Moroccan "Lawh" (tablet) concept. The application uses the Warsh narration where each "page" corresponds to a **Thumn** (1/8 of a Hizb).

### Core Philosophy
- **Visual Comfort**: Optimized for long reading sessions and visually impaired users.
- **Traditional Structure**: Adherence to the Thumn-based division typical of Moroccan Quranic schools.
- **Accessibility**: 100% free, utilizing open APIs and Firebase Free Tier.

---

## 2. Target Audience
- **Hifz Students**: Students following the traditional Moroccan curriculum.
- **Talabat al-'Ilm**: Seekers of knowledge requiring a structured tool for review.
- **Elderly / Visually Impaired**: Users needing large fonts, high contrast, and simplified navigation.
- **Daily Readers**: Individuals seeking a premium, distraction-free reading experience.

---

## 3. Technical Stack
- **Framework**: Flutter (Android, iOS, Tablet support).
- **Backend**: Firebase.
- **Authentication**: Firebase Auth (Email/Password).
- **Database**: Cloud Firestore.
- **Firebase Configuration**:
    ```javascript
    const firebaseConfig = {
      apiKey: "AIzaSyB133olDzTvK3Zdlu7tRMXW9SfM5RPd7PU",
      authDomain: "lawhi-antigravity.firebaseapp.com",
      projectId: "lawhi-antigravity",
      storageBucket: "lawhi-antigravity.firebasestorage.app",
      messagingSenderId: "555731163427",
      appId: "1:555731163427:web:5c68d763eb35d7f3655496"
    };
    ```
- **External APIs**: Free Quran APIs (e.g., Quran.com API, AlQuran.cloud) for text data and audio streaming.

- **Storage**: Firebase Storage (minimal usage for assets).

---

## 4. Functional Requirements

### 4.1 Mushaf Navigation & Display
- **Narration**: Warsh (Moroccan edition).
- **Structure**: 1 Page = 1 Thumn.
- **Navigation Menu**: Browse by Surah, Juz, Hizb, and Thumn.
- **UI Customization**:
    - Adjustable font size (Slider).
    - Background themes: Pastel colors (Cream, Green, Blue) and Dark Mode.
    - Custom fonts (Arabic typography).

### 4.2 User Tracking (Sites)
Four distinct markers saved per user:
1. **Learning (حفظ)**: Current memorization progress.
2. **Reviewing (مراجعة)**: Current review progress.
3. **Reading (تلاوة)**: Daily reading routine.
4. **Browsing (تصفح)**: Last visited location.

Each site stores: `surah_id`, `hizb_number`, `thumn_number`, `line/ayah_number`, and `timestamp`.

### 4.3 Interactive Features
- **Auto-Scroll**: Vertical text movement with three speed settings (Slow, Medium, Fast).
- **Global Search**: Search by keywords in Arabic text. Results link directly to the Thumn with the Ayah highlighted.
- **Audio Recitation**: Streaming audio per Ayah via free APIs. Standard playback controls (Play/Pause, Prev/Next).

### 4.4 Data Synchronization
- Users can log in to sync their preferences and saved sites across multiple devices.
- Guest mode available (local storage only).

---

## 5. Non-Functional Requirements
- **Performance**: Instant loading of text data.
- **Offline Support**: Cache recently read Thumns.
- **Scalability**: Designed to stay within Firebase Free Tier limits (50k reads/day).
- **Security**: Firestore Rules to ensure data privacy (User A cannot read User B's sites).

---

## 6. Future Roadmap
- Integration of Google/Apple Sign-in.
- Daily Hifz goals and notifications.
- Audio recording for self-testing.
- Tajweed color-coding.
