# Barber Booking — REST API Hujjatlari

Barcha API so'rovlari JSON formatida qabul qilinadi va qaytariladi.
Autentifikatsiya `Authorization: Bearer <token>` sarlavhasi orqali amalga oshiriladi.

Jonli interaktiv Swagger UI: `http://localhost:8000/api/docs/`
OpenAPI sxemasi: `http://localhost:8000/api/schema/`
Redoc UI: `http://localhost:8000/api/redoc/`

---

## 1. Autentifikatsiya va Profil (/api/auth/)

### `POST /api/auth/register/customer/`
Mijoz sifatida ro'yxatdan o'tish.
- **Request Body:**
  ```json
  {
    "phone_number": "+998905555555",
    "full_name": "Sanjar Karimov",
    "password": "Password123!",
    "password_confirm": "Password123!",
    "terms_accepted": true
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "message": "Mijoz muvaffaqiyatli ro'yxatdan o'tdi",
    "access": "eyJhbGciOi...",
    "refresh": "eyJhbGciOi...",
    "user": { ... }
  }
  ```

### `POST /api/auth/register/barber/`
Sartarosh sifatida ro'yxatdan o'tish (profil holati: `pending`).
- **Request Body:**
  ```json
  {
    "phone_number": "+998901111111",
    "full_name": "Sardor Aliyev",
    "barbershop_name": "Chorsu Barber Club",
    "address": "Navoiy ko'chasi 14",
    "bio": "Tajribali usta",
    "experience_years": 8,
    "password": "Password123!",
    "password_confirm": "Password123!"
  }
  ```

### `POST /api/auth/login/`
JWT tokenlarni olish.
- **Request Body:**
  ```json
  {
    "phone_number": "+998905555555",
    "password": "customer123"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "access": "eyJ...",
    "refresh": "eyJ...",
    "user": {
      "id": 1,
      "full_name": "Sanjar Karimov",
      "role": "CUSTOMER"
    }
  }
  ```

### `GET /api/auth/me/`
Joriy foydalanuvchi ma'lumotlarini olish.

---

## 2. Sartaroshlar va Xizmatlar (/api/barbers/)

### `GET /api/barbers/`
Tasdiqlangan sartaroshlar ro'yxatini olish.
- **Query Parametrlari:**
  - `search`: Ism, salon yoki manzil bo'yicha qidirish
  - `service`: Xizmat nomi bo'yicha filter
  - `min_rating`: Minimal reyting (masalan `4.5`)
  - `sort_by`: `rating`, `experience`, `newest`

### `GET /api/barbers/{id}/`
Sartaroshning batafsil profili, xizmatlari va ish soatlarini olish.

### `GET /api/barbers/dashboard/overview/`
Sartarosh kabineti uchun umumiy ko'rsatkichlar (bugungi qabullar, tushum, oylik aylanma).

### `GET /api/barbers/dashboard/working-hours/` & `POST`
Ish kunlari va vaqtlarini ko'rish hamda saqlash.

### `GET /api/barbers/dashboard/my-services/`
Sartarosh o'z xizmatlarini boshqarishi (CRUD).

### `GET /api/barbers/dashboard/revenue-stats/`
Haftalik daromad grafigi, talabgir xizmatlar va bekor qilinganlar statistikasi.

---

## 3. Buyurtmalar va Qabullar (/api/appointments/)

### `GET /api/appointments/available-slots/`
Tanlangan sartarosh va sana bo'yicha real vaqtdagi bo'sh qabul vaqtlarini hisoblab berish.
- **Query Parametrlari:** `barber_id`, `date` (YYYY-MM-DD), `service_id`
- **Response:**
  ```json
  {
    "barber_id": 1,
    "date": "2026-10-15",
    "available_slots": [
      {"start_time": "09:00", "end_time": "09:30"},
      {"start_time": "09:30", "end_time": "10:00"},
      {"start_time": "10:30", "end_time": "11:00"}
    ]
  }
  ```

### `POST /api/appointments/book/`
Yangi qabulga yozilish (xavfsiz tranzaksiya blokirovkasi bilan).
- **Request Body:**
  ```json
  {
    "barber_id": 1,
    "service_id": 2,
    "appointment_date": "2026-10-15",
    "time_str": "10:30",
    "notes": "Eslatma"
  }
  ```

### `GET /api/appointments/my-appointments/`
Mijoz qabullari ro'yxati (`?status=upcoming|pending|completed|cancelled`).

### `POST /api/appointments/{id}/status/`
Sartarosh tomonidan holatni o'zgartirish (`confirmed`, `completed`, `cancelled`, `no_show`).

### `POST /api/appointments/{id}/cancel/`
Buyurtmani bekor qilish.

### `POST /api/appointments/{id}/reschedule/`
Qabul vaqtini boshqa sanaga ko'chirish.

---

## 4. Sharhlar va Sevimlilar

### `POST /api/reviews/`
Yakunlangan qabul bo'yicha 1-5 yulduzli baho va izoh yozish.

### `POST /api/appointments/favorites/toggle/`
Sartaroshni sevimlilarga qo'shish yoki o'chirish (`{"barber_id": 1}`).
