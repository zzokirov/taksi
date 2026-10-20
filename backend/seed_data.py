import os
import django
from datetime import date, time, timedelta

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.utils import timezone
from apps.accounts.models import User, BarberProfile, CustomerProfile, Barbershop
from apps.barbers.models import Service, WorkingHours, BreakTime
from apps.appointments.models import Appointment, Favorite
from apps.reviews.models import Review
from apps.administration.models import SubscriptionPlan

def seed():
    print("Seeding initial data...")

    # 1. Admin
    admin_user, _ = User.objects.get_or_create(
        phone_number="+998900000001",
        defaults={
            'first_name': 'Admin',
            'last_name': 'Superuser',
            'role': User.Role.ADMIN,
            'is_staff': True,
            'is_superuser': True,
        }
    )
    admin_user.set_password("admin123")
    admin_user.save()
    print("Admin created: +998900000001 / admin123")

    # 2. Barbershops
    shop1, _ = Barbershop.objects.get_or_create(
        name="Chorsu Barber Club",
        defaults={
            'address': "Toshkent sh., Navoiy ko'chasi 14-uy",
            'city': "Toshkent",
            'latitude': 41.311081,
            'longitude': 69.240562,
            'phone': "+998712001122",
            'description': "Zamonaviy erkaklar sartaroshxonasi. Yuqori sifat va qulaylik."
        }
    )

    shop2, _ = Barbershop.objects.get_or_create(
        name="Royal Fade Lounge",
        defaults={
            'address': "Toshkent sh., Amir Temur shoh ko'chasi 25",
            'city': "Toshkent",
            'latitude': 41.325500,
            'longitude': 69.280100,
            'phone': "+998712334455",
            'description': "Premium darajadagi sartaroshlik xizmatlari."
        }
    )

    # 3. Barbers
    # Barber 1: Sardor
    u_barber1, _ = User.objects.get_or_create(
        phone_number="+998901111111",
        defaults={'first_name': 'Sardor', 'last_name': 'Aliyev', 'role': User.Role.BARBER}
    )
    u_barber1.set_password("barber123")
    u_barber1.save()

    b_profile1, _ = BarberProfile.objects.get_or_create(
        user=u_barber1,
        defaults={
            'barbershop': shop1,
            'barbershop_name': shop1.name,
            'address': shop1.address,
            'bio': "10 yillik tajribaga ega usta. Klassik va zamonaviy soch turmaklari ustasi.",
            'experience_years': 8,
            'is_verified': True,
            'verification_status': BarberProfile.VerificationStatus.APPROVED,
            'rating_avg': 4.9,
            'rating_count': 28,
            'slot_interval_minutes': 30,
            'advance_booking_days': 14,
        }
    )

    # Services for Barber 1
    s1_1, _ = Service.objects.get_or_create(
        barber=b_profile1, name="Klassik Soch Qirqish",
        defaults={'description': "Soch yuvish, qirqish va fenlash bilan", 'price': 60000, 'duration_minutes': 30}
    )
    s1_2, _ = Service.objects.get_or_create(
        barber=b_profile1, name="Soqol Tekislash & Oformleniye",
        defaults={'description': "Issiq sochiq va maxsus moy bilan soqol parvarishi", 'price': 40000, 'duration_minutes': 25}
    )
    s1_3, _ = Service.objects.get_or_create(
        barber=b_profile1, name="VIP Kompleks (Soch + Soqol + Mask)",
        defaults={'description': "To'liq obraz, yuz tozalash va massaj", 'price': 120000, 'duration_minutes': 60}
    )

    # Working hours for Barber 1
    for day in range(7):
        WorkingHours.objects.get_or_create(
            barber=b_profile1,
            day_of_week=day,
            defaults={
                'is_working_day': (day != 6), # Sunday off
                'start_time': time(9, 0),
                'end_time': time(20, 0)
            }
        )
    BreakTime.objects.get_or_create(
        barber=b_profile1,
        day_of_week=0,
        defaults={'start_time': time(13, 0), 'end_time': time(14, 0), 'title': 'Tushlik'}
    )

    # Barber 2: Jasur
    u_barber2, _ = User.objects.get_or_create(
        phone_number="+998902222222",
        defaults={'first_name': 'Jasur', 'last_name': 'Toshmatov', 'role': User.Role.BARBER}
    )
    u_barber2.set_password("barber123")
    u_barber2.save()

    b_profile2, _ = BarberProfile.objects.get_or_create(
        user=u_barber2,
        defaults={
            'barbershop': shop2,
            'barbershop_name': shop2.name,
            'address': shop2.address,
            'bio': "Fade va soqol dizayni bo'yicha chempion. Zamonaviy uslublar.",
            'experience_years': 5,
            'is_verified': True,
            'verification_status': BarberProfile.VerificationStatus.APPROVED,
            'rating_avg': 4.8,
            'rating_count': 19,
            'slot_interval_minutes': 30,
            'advance_booking_days': 10,
        }
    )
    Service.objects.get_or_create(
        barber=b_profile2, name="Skin Fade & Styling",
        defaults={'description': "Professional fade va teksturali turmak", 'price': 70000, 'duration_minutes': 35}
    )
    Service.objects.get_or_create(
        barber=b_profile2, name="Bolalar Soch Turmagi",
        defaults={'description': "12 yoshgacha bolalar uchun qulay va tez", 'price': 50000, 'duration_minutes': 30}
    )
    for day in range(7):
        WorkingHours.objects.get_or_create(
            barber=b_profile2,
            day_of_week=day,
            defaults={'is_working_day': True, 'start_time': time(10, 0), 'end_time': time(21, 0)}
        )

    # Barber 3 (Pending approval)
    u_barber3, _ = User.objects.get_or_create(
        phone_number="+998904444444",
        defaults={'first_name': 'Rustam', 'last_name': 'Qodirov', 'role': User.Role.BARBER}
    )
    u_barber3.set_password("barber123")
    u_barber3.save()
    b_profile3, _ = BarberProfile.objects.get_or_create(
        user=u_barber3,
        defaults={
            'barbershop_name': "Yunusobod Barbershop",
            'address': "Yunusobod 4-mavze",
            'bio': "Yangi ro'yxatdan o'tgan usta",
            'is_verified': False,
            'verification_status': BarberProfile.VerificationStatus.PENDING,
        }
    )

    # 4. Customers
    u_cust1, _ = User.objects.get_or_create(
        phone_number="+998905555555",
        defaults={'first_name': 'Sanjar', 'last_name': 'Karimov', 'role': User.Role.CUSTOMER}
    )
    u_cust1.set_password("customer123")
    u_cust1.save()
    CustomerProfile.objects.get_or_create(user=u_cust1, defaults={'notes': 'Muntazam mijoz'})

    u_cust2, _ = User.objects.get_or_create(
        phone_number="+998906666666",
        defaults={'first_name': 'Azizbek', 'last_name': 'Rahimov', 'role': User.Role.CUSTOMER}
    )
    u_cust2.set_password("customer123")
    u_cust2.save()
    CustomerProfile.objects.get_or_create(user=u_cust2)

    # 5. Favorite
    Favorite.objects.get_or_create(customer=u_cust1, barber=b_profile1)

    # 6. Appointments
    today = timezone.localdate()
    # Completed appointment yesterday
    yesterday = today - timedelta(days=1)
    appt1, created1 = Appointment.objects.get_or_create(
        customer=u_cust1,
        barber=b_profile1,
        appointment_date=yesterday,
        defaults={
            'service': s1_1,
            'service_name': s1_1.name,
            'service_price': s1_1.price,
            'service_duration_minutes': s1_1.duration_minutes,
            'start_time': time(11, 0),
            'end_time': time(11, 30),
            'status': Appointment.Status.COMPLETED
        }
    )
    if created1:
        Review.objects.get_or_create(
            appointment=appt1,
            defaults={
                'customer': u_cust1,
                'barber': b_profile1,
                'rating': 5,
                'comment': "Juda zo'r xizmat! Soch turmagi ajoyib chiqdi, tavsiya qilaman."
            }
        )

    # Upcoming appointment tomorrow
    tomorrow = today + timedelta(days=1)
    Appointment.objects.get_or_create(
        customer=u_cust1,
        barber=b_profile1,
        appointment_date=tomorrow,
        defaults={
            'service': s1_2,
            'service_name': s1_2.name,
            'service_price': s1_2.price,
            'service_duration_minutes': s1_2.duration_minutes,
            'start_time': time(15, 0),
            'end_time': time(15, 25),
            'status': Appointment.Status.CONFIRMED
        }
    )

    # 7. Subscription Plans
    SubscriptionPlan.objects.get_or_create(
        name="Standart Tarif",
        defaults={
            'description': "Kichik va o'rta sartaroshlar uchun asosiy funksiyalar",
            'price': 150000,
            'duration_days': 30,
            'max_services': 10,
            'features': ["Onlayn qabullar", "Grafik boshqaruvi", "Statistika"]
        }
    )
    SubscriptionPlan.objects.get_or_create(
        name="Premium VIP Tarif",
        defaults={
            'description': "Mashhur ustalar va salonlar uchun cheksiz imkoniyatlar",
            'price': 300000,
            'duration_days': 30,
            'max_services': 50,
            'features': ["Cheksiz xizmatlar", "SMS va Push bildirishnomalar", "Kengaytirilgan moliya hisoboti"]
        }
    )

    print("Seed completed successfully!")

if __name__ == '__main__':
    seed()
