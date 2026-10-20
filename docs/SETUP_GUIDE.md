# Barber Booking — O'rnatish va Ishga Tushirish Qo'llanmasi

Ushbu qo'llanmada **Barber Booking** loyihasining Django backend va Flutter Android mobil ilovasini noldan o'rnatish, ma'lumotlar bazasini sozlash, test qilish va Android APK / AAB paketlarini yaratish ko'rsatilgan.

---

## 1. Tizim Talablari

- **OS:** Windows 10/11, macOS yoki Linux
- **Python:** 3.10 yoki undan yuqori (tavsiya etiladi: 3.11 - 3.13)
- **Flutter SDK:** 3.20+ (mavjud: 3.41.9)
- **Android SDK:** API 24 (Android 7.0) va undan yuqori (tavsiya etiladi: API 34/35)
- **Java Development Kit (JDK):** JDK 17 yoki 21 (Android Studio jbr)
- **Ma'lumotlar bazasi:** PostgreSQL 15+ (ishlab chiqish uchun SQLite avtomatik fallback mavjud)

---

## 2. Backend (Django REST Framework) O'rnatish

### 2.1. Virtual Muhitni faollashtirish
Loyihaning `backend/` papkasiga o'ting:
```bash
cd backend
python -m venv venv
```

Windows PowerShell:
```powershell
.\venv\Scripts\Activate.ps1
```

Linux / macOS:
```bash
source venv/bin/activate
```

### 2.2. Paketlarni o'rnatish
```bash
pip install -r requirements.txt
```

### 2.3. Muhit Sozlamalari (.env)
`backend/.env` faylini oching va kerakli parametrlarni o'rnating:
```env
SECRET_KEY=django-insecure-barber-booking-production-secret-key-2026-change-in-prod
DEBUG=True
ALLOWED_HOSTS=*
CORS_ALLOW_ALL_ORIGINS=True

# PostgreSQL Sozlamalari
DB_ENGINE=django.db.backends.postgresql
DB_NAME=barber_db
DB_USER=postgres
DB_PASSWORD=sizning_postgres_parolingiz
DB_HOST=localhost
DB_PORT=5432
USE_SQLITE_FALLBACK=True

# Firebase Push Bildirishnomalari (ixtiyoriy)
FCM_SERVER_KEY=
```
> **Eslatma:** Agar PostgreSQL ulanmasa yoki o'rnatilmagan bo'lsa, tizim avtomatik tarzda `db.sqlite3` bazasiga o'tadi va to'liq ishlashda davom etadi.

### 2.4. Migratsiyalarni Qo'llash
```bash
python manage.py makemigrations accounts barbers appointments reviews notifications administration
python manage.py migrate
```

### 2.5. Boshlang'ich Ma'lumotlarni Yuklash (Seed Data)
Loyihada test qilish uchun tayyor administrator, sartaroshlar, xizmatlar va buyurtmalar yaratilgan:
```bash
python seed_data.py
```

Tayyor foydalanuvchi hisoblari:
- **Administrator:** `+998900000001` / parol: `admin123`
- **Sartarosh (Sardor Aliyev):** `+998901111111` / parol: `barber123`
- **Sartarosh (Jasur Style):** `+998902222222` / parol: `barber123`
- **Mijoz (Sanjar Karimov):** `+998905555555` / parol: `customer123`

### 2.6. Backend Serverni Ishga Tushirish
```bash
python manage.py runserver 0.0.0.0:8000
```
- **Web Admin Dashboard:** `http://localhost:8000/dashboard/`
- **Django Standard Admin:** `http://localhost:8000/admin/`
- **Swagger API Docs:** `http://localhost:8000/api/docs/`

---

## 3. Flutter Mobil Ilovani Ishga Tushirish

### 3.1. Bog'liqliklarni yuklash
```bash
cd mobile
flutter pub get
```

### 3.2. Ilovani Ishga Tushirish
Android emulyatorda ishga tushirish:
```bash
flutter run
```

Haqiqiy Android telefonda (USB yoki Wi-Fi orqali ulangan holda):
Kompyuteringizning mahalliy IP manzilini kiriting (masalan: `192.168.1.100`):
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000
```

---

## 4. Android Build va APK / AAB Yaratish

### 4.1. Test Uchun Debug APK Yaratish
```bash
flutter build apk --debug
```
Yaratilgan APK fayl manzili:
`mobile/build/app/outputs/flutter-apk/app-debug.apk`

Ushbu APK ni istalgan Android smartfonga o'rnatib test qilish mumkin:
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 4.2. Release APK Yaratish (To'g'ridan-to'g'ri o'rnatish uchun)
```bash
flutter build apk --release
```
Natija:
`mobile/build/app/outputs/flutter-apk/app-release.apk`

### 4.3. Google Play Uchun Android App Bundle (AAB) Yaratish
Google Play do'koniga yuklash uchun `.aab` formati talab qilinadi:

1. **Keystore yaratish (agar mavjud bo'lmasa):**
   ```bash
   keytool -genkey -v -keystore barber-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias barber
   ```
2. **`mobile/android/key.properties` faylini yaratish:**
   ```properties
   storePassword=sizning_parolingiz
   keyPassword=sizning_parolingiz
   keyAlias=barber
   storeFile=../barber-release-key.jks
   ```
3. **App Bundle yaratish:**
   ```bash
   flutter build appbundle --release
   ```
   Natija:
   `mobile/build/app/outputs/bundle/release/app-release.aab`
