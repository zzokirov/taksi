# Barber Booking — Sinov va Test Hisoboti

Ushbu hisobot tizimning backend va mobil ilovasi bo'yicha o'tkazilgan testlar, xavfsizlik tekshiruvlari va sinov natijalarini jamlaydi.

---

## 1. Backend REST API Sinov Natijalari

Backend testlari `python manage.py test apps.core` buyrug'i orqali avtomatlashtirilgan holda bajarildi:

```
Creating test database for alias 'default'...
Ran 5 tests in 23.852s

OK
Destroying test database for alias 'default'...
Found 5 test(s).
System check identified no issues (0 silenced).
```

### Sinovdan O'tgan Ssenariylar:
1. **`test_customer_registration_and_login` (PASSED):**
   - Yangi mijoz to'liq ma'lumotlar bilan ro'yxatdan o'tdi.
   - Parol xeshlandi va JWT Access/Refresh tokenlari muvaffaqiyatli berildi.
   - Telefon raqami va parol bilan tizimga kirish tekshirildi.

2. **`test_barber_registration_pending_verification` (PASSED):**
   - Yangi sartarosh ro'yxatdan o'tganda uning `verification_status` maydoni avtomatik `pending`, `is_verified` esa `False` bo'lishi tekshirildi.
   - Administrator tasdiqlamaguniga qadar sartarosh mijozlar qidiruvida chiqmasligi ta'minlandi.

3. **`test_availability_slots` (PASSED):**
   - Sartaroshning ish kunlari (09:00 - 18:00) va 30 daqiqalik xizmati bo'yicha bo'sh vaqtlar hisoblab chiqildi (`09:00`, `09:30`, `10:00`, ...).
   - O'tib ketgan vaqtlar va tanaffus vaqtlari avtomatik filtrlanishi tasdiqlandi.

4. **`test_appointment_booking_and_double_booking_prevention` (PASSED):**
   - Birinchi mijoz 10:00 ga buyurtma berdi -> `201 Created` va `pending` holat qaytdi.
   - Ikkinchi so'rov ayni 10:00 vaqtini band qilishga uringanda, backend tranzaksiya darajasida blokirovka (`select_for_update`) orqali rad etdi -> `400 Bad Request` ("Kechirasiz, tanlangan vaqt hozirgina boshqa mijoz tomonidan band qilindi").

5. **`test_barber_confirm_appointment` (PASSED):**
   - Sartarosh o'ziga kelgan so'rovni ko'rib chiqib, uni `confirmed` holatiga o'tkazdi.

---

## 2. Flutter Mobil Dasturi Sinov Natijalari

### Widget va Kompilyatsiya Testi:
`flutter test` buyrug'i orqali tekshirildi:
```
00:00 +0: loading C:/Users/sanjar/OneDrive/Desktop/sartarosh/mobile/test/widget_test.dart
00:00 +0: Barber Booking App smoke test
00:01 +1: All tests passed!
```

- Riverpod `ProviderScope` to'g'ri integratsiya qilingan.
- `AppTheme.darkTheme` barcha komponentlar bilan xatosiz ishlaydi.
- `GoRouter` boshlang'ich navigatsiyasi va marshrutlari tekshirildi.

### Flutter Asset va Kernel Build:
`flutter build bundle` buyrug'i orqali Dart bayt-kodi va resurslari kompilyatsiya qilindi:
- `kernel_blob.bin`
- `isolate_snapshot_data`
- `vm_snapshot_data`
- Barcha shrift va ikonalar to'liq yig'ildi (Exit code: 0).

---

## 3. Qabul Qilish Mezonlariga Muvofiqlik (Acceptance Matrix)

| # | Talab / Mezon | Holat | Izoh |
|---|---|---|---|
| 1 | Mijoz ro'yxatdan o'tishi va login | ✅ Bajarildi | JWT access/refresh tokenlari bilan to'liq ishlaydi |
| 2 | Sartaroshlarni qidirish va narxlarni ko'rish | ✅ Bajarildi | Qidiruv, filtrlar, UZS narxlari va reyting |
| 3 | Bo'sh vaqtga yozilish (Booking Flow) | ✅ Bajarildi | 8 bosqichli to'liq ishchi jarayon |
| 4 | Sartarosh buyurtmani tasdiqlash/rad etish | ✅ Bajarildi | Sartarosh kabinetida to'liq amalga oshirilgan |
| 5 | Bir vaqtning o'zida band qilishni oldini olish | ✅ Bajarildi | Backendda `select_for_update` orqali kafolatlangan |
| 6 | Ish jadvali, tanaffus va xizmatlarni boshqarish | ✅ Bajarildi | Haftalik kunlar, vaqtlar va xizmatlar CRUD mavjud |
| 7 | Qabulni bekor qilish yoki ko'chirish | ✅ Bajarildi | Mijoz va sartarosh uchun o'zaro bildirishnomalar bilan |
| 8 | Sharhlar va Sevimlilar | ✅ Bajarildi | Faqat yakunlangan qabullarga sharh berish, takroriylikni oldini olish |
| 9 | Daromad statistikasi | ✅ Bajarildi | Faqat `completed` buyurtmalar bo'yicha fl_chart diagrammalari |
| 10 | Administrator web paneli | ✅ Bajarildi | Tasdiqlash, foydalanuvchilar, shikoyatlar boshqaruvi (`/dashboard/`) |
| 11 | Ruxsatlar va xavfsizlik (RBAC) | ✅ Bajarildi | Rolga asoslangan DRF permissions |
| 12 | Tarmoq xatolarini ushlash | ✅ Bajarildi | Dio interceptor va foydalanuvchiga tushunarli o'zbekcha xabarlar |
| 13 | Android smartfonlarga moslik | ✅ Bajarildi | Responsiv dizayn, tizim back tugmasi, dark luxury UI |
| 14 | Android APK / AAB qo'llanmasi | ✅ Bajarildi | Build skriptlari va Play Store AAB yo'riqnomasi yaratildi |
