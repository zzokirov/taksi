from datetime import date, time, timedelta
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from apps.accounts.models import User, BarberProfile, CustomerProfile
from apps.barbers.models import Service, WorkingHours
from apps.appointments.models import Appointment
from apps.appointments.availability import get_available_slots

class BarberBookingAPITestCase(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Admin
        self.admin_user = User.objects.create_superuser(
            phone_number="+998900000001",
            password="adminpassword",
            first_name="Admin"
        )

        # Barber
        self.barber_user = User.objects.create_user(
            phone_number="+998901111111",
            password="barberpassword",
            first_name="Sardor",
            last_name="Aliyev",
            role=User.Role.BARBER
        )
        self.barber_profile = BarberProfile.objects.create(
            user=self.barber_user,
            barbershop_name="Elite Barbershop",
            address="Toshkent, Chilonzor",
            is_verified=True,
            verification_status=BarberProfile.VerificationStatus.APPROVED,
            slot_interval_minutes=30,
            advance_booking_days=14
        )
        self.service = Service.objects.create(
            barber=self.barber_profile,
            name="Soch kesish",
            price=50000,
            duration_minutes=30
        )
        # Working hours
        for day in range(7):
            WorkingHours.objects.create(
                barber=self.barber_profile,
                day_of_week=day,
                is_working_day=True,
                start_time=time(9, 0),
                end_time=time(18, 0)
            )

        # Customer
        self.customer_user = User.objects.create_user(
            phone_number="+998902222222",
            password="customerpassword",
            first_name="Sanjar",
            last_name="Karimov",
            role=User.Role.CUSTOMER
        )
        CustomerProfile.objects.create(user=self.customer_user)

    def test_customer_registration_and_login(self):
        """Test customer registration and JWT login."""
        reg_res = self.client.post('/api/auth/register/customer/', {
            'phone_number': '+998903333333',
            'full_name': 'Jasur Mirzayev',
            'password': 'SecurePassword123!',
            'password_confirm': 'SecurePassword123!',
            'terms_accepted': True
        })
        self.assertEqual(reg_res.status_code, status.HTTP_201_CREATED)
        self.assertIn('access', reg_res.data)

        # Login
        login_res = self.client.post('/api/auth/login/', {
            'phone_number': '+998903333333',
            'password': 'SecurePassword123!'
        })
        self.assertEqual(login_res.status_code, status.HTTP_200_OK)
        self.assertIn('access', login_res.data)
        self.assertEqual(login_res.data['user']['role'], 'CUSTOMER')

    def test_barber_registration_pending_verification(self):
        """Test barber registration status is pending until verified."""
        reg_res = self.client.post('/api/auth/register/barber/', {
            'phone_number': '+998904444444',
            'full_name': 'Otabek Barber',
            'barbershop_name': 'New Shop',
            'address': 'Toshkent',
            'password': 'SecurePassword123!',
            'password_confirm': 'SecurePassword123!'
        })
        self.assertEqual(reg_res.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(phone_number='+998904444444')
        self.assertEqual(user.barber_profile.verification_status, 'pending')
        self.assertFalse(user.barber_profile.is_verified)

    def test_availability_slots(self):
        """Test available slots calculation."""
        target_date = timezone.localdate() + timedelta(days=2)
        slots = get_available_slots(self.barber_profile, target_date, service_duration_minutes=30)
        self.assertTrue(len(slots) > 0)
        self.assertEqual(slots[0]['start_time'], '09:00')

    def test_appointment_booking_and_double_booking_prevention(self):
        """Test appointment booking and verify backend prevents double booking."""
        self.client.force_authenticate(user=self.customer_user)
        target_date = timezone.localdate() + timedelta(days=2)

        # 1. Book first appointment at 10:00
        res1 = self.client.post('/api/appointments/book/', {
            'barber_id': self.barber_profile.id,
            'service_id': self.service.id,
            'appointment_date': str(target_date),
            'time_str': '10:00',
            'notes': 'Iltimos, aniq vaqtida boshlaylik'
        })
        self.assertEqual(res1.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res1.data['status'], 'pending')

        # 2. Try booking the exact same slot again -> MUST BE REJECTED
        res2 = self.client.post('/api/appointments/book/', {
            'barber_id': self.barber_profile.id,
            'service_id': self.service.id,
            'appointment_date': str(target_date),
            'time_str': '10:00'
        })
        self.assertEqual(res2.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('time_str', res2.data)

    def test_barber_confirm_appointment(self):
        """Test barber receives and can confirm booking."""
        target_date = timezone.localdate() + timedelta(days=2)
        appt = Appointment.objects.create(
            customer=self.customer_user,
            barber=self.barber_profile,
            service=self.service,
            service_name=self.service.name,
            service_price=self.service.price,
            service_duration_minutes=self.service.duration_minutes,
            appointment_date=target_date,
            start_time=time(14, 0),
            end_time=time(14, 30),
            status=Appointment.Status.PENDING
        )

        self.client.force_authenticate(user=self.barber_user)
        res = self.client.post(f'/api/appointments/{appt.id}/status/', {
            'status': 'confirmed'
        })
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        appt.refresh_from_db()
        self.assertEqual(appt.status, Appointment.Status.CONFIRMED)
