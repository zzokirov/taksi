from datetime import datetime, time, timedelta
from django.db import transaction
from django.utils import timezone
from rest_framework import serializers
from .models import Appointment, Favorite
from apps.accounts.models import BarberProfile, User
from apps.barbers.models import Service, WorkingHours, BreakTime, BlockedTimeSlot
from apps.barbers.serializers import BarberListSerializer

class AppointmentCreateSerializer(serializers.ModelSerializer):
    barber_id = serializers.IntegerField(write_only=True)
    service_id = serializers.IntegerField(write_only=True)
    time_str = serializers.CharField(write_only=True, help_text="Format: HH:MM masalan 14:30")

    class Meta:
        model = Appointment
        fields = [
            'id', 'barber_id', 'service_id', 'appointment_date',
            'time_str', 'notes', 'status', 'created_at'
        ]
        read_only_fields = ['id', 'status', 'created_at']

    def validate(self, attrs):
        barber_id = attrs.get('barber_id')
        service_id = attrs.get('service_id')
        appt_date = attrs.get('appointment_date')
        time_str = attrs.get('time_str')

        # 1. Validate barber
        try:
            barber = BarberProfile.objects.get(id=barber_id)
        except BarberProfile.DoesNotExist:
            raise serializers.ValidationError({"barber_id": "Sartarosh topilmadi!"})

        # 2. Validate service
        try:
            service = Service.objects.get(id=service_id, barber=barber, is_active=True)
        except Service.DoesNotExist:
            raise serializers.ValidationError({"service_id": "Tanlangan xizmat faol emas yoki mavjud emas!"})

        # 3. Validate date
        today = timezone.localdate()
        if appt_date < today:
            raise serializers.ValidationError({"appointment_date": "O'tib ketgan sanaga buyurtma berib bo'lmaydi!"})
        if appt_date > today + timedelta(days=barber.advance_booking_days):
            raise serializers.ValidationError({
                "appointment_date": f"Bu sartaroshga ko'pi bilan {barber.advance_booking_days} kun oldin yozilish mumkin!"
            })

        # 4. Parse time
        try:
            start_t = datetime.strptime(time_str.strip(), '%H:%M').time()
        except ValueError:
            raise serializers.ValidationError({"time_str": "Vaqt formati noto'g'ri, masalan: 14:30"})

        duration_mins = service.duration_minutes
        end_dt = datetime.combine(appt_date, start_t) + timedelta(minutes=duration_mins)
        end_t = end_dt.time()

        if appt_date == today:
            buffer_time = (timezone.localtime() + timedelta(minutes=5)).time()
            if start_t < buffer_time:
                raise serializers.ValidationError({"time_str": "Tanlangan vaqt o'tib ketgan!"})

        attrs['barber_obj'] = barber
        attrs['service_obj'] = service
        attrs['parsed_start_time'] = start_t
        attrs['parsed_end_time'] = end_t
        return attrs

    def create(self, validated_data):
        customer = self.context['request'].user
        barber = validated_data['barber_obj']
        service = validated_data['service_obj']
        appt_date = validated_data['appointment_date']
        start_time = validated_data['parsed_start_time']
        end_time = validated_data['parsed_end_time']
        notes = validated_data.get('notes', '')

        # Safe Concurrent Locking: Prevent Double Booking
        with transaction.atomic():
            # Lock the barber's active appointments on this date
            conflict = Appointment.objects.select_for_update().filter(
                barber=barber,
                appointment_date=appt_date,
                status__in=[Appointment.Status.PENDING, Appointment.Status.CONFIRMED],
                start_time__lt=end_time,
                end_time__gt=start_time
            ).exists()

            if conflict:
                raise serializers.ValidationError({
                    "time_str": "Kechirasiz, tanlangan vaqt hozirgina boshqa mijoz tomonidan band qilindi! Iltimos, boshqa vaqtni tanlang."
                })

            appointment = Appointment.objects.create(
                customer=customer,
                barber=barber,
                service=service,
                service_name=service.name,
                service_price=service.price,
                service_duration_minutes=service.duration_minutes,
                appointment_date=appt_date,
                start_time=start_time,
                end_time=end_time,
                notes=notes,
                status=Appointment.Status.PENDING
            )

        return appointment

class AppointmentListSerializer(serializers.ModelSerializer):
    barber_name = serializers.CharField(source='barber.user.full_name', read_only=True)
    barber_phone = serializers.CharField(source='barber.user.phone_number', read_only=True)
    barber_avatar = serializers.SerializerMethodField()
    barbershop_name = serializers.CharField(source='barber.barbershop_name', read_only=True)
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone_number', read_only=True)
    formatted_date = serializers.SerializerMethodField()
    formatted_time = serializers.SerializerMethodField()
    can_cancel = serializers.SerializerMethodField()
    can_review = serializers.SerializerMethodField()
    has_review = serializers.SerializerMethodField()

    class Meta:
        model = Appointment
        fields = [
            'id', 'customer', 'customer_name', 'customer_phone',
            'barber', 'barber_name', 'barber_phone', 'barber_avatar', 'barbershop_name',
            'service', 'service_name', 'service_price', 'service_duration_minutes',
            'appointment_date', 'start_time', 'end_time',
            'formatted_date', 'formatted_time', 'status', 'notes',
            'rejection_reason', 'cancellation_reason',
            'can_cancel', 'can_review', 'has_review',
            'created_at'
        ]

    def get_barber_avatar(self, obj):
        if obj.barber and obj.barber.avatar:
            return obj.barber.avatar.url
        return None

    def get_formatted_date(self, obj):
        return obj.appointment_date.strftime('%d.%m.%Y')

    def get_formatted_time(self, obj):
        return f"{obj.start_time.strftime('%H:%M')} - {obj.end_time.strftime('%H:%M')}"

    def get_can_cancel(self, obj):
        if obj.status in [Appointment.Status.CANCELLED, Appointment.Status.COMPLETED, Appointment.Status.NO_SHOW]:
            return False
        # Customer can cancel at least 2 hours before
        now = timezone.localtime()
        appt_dt = timezone.make_aware(datetime.combine(obj.appointment_date, obj.start_time))
        return appt_dt > now + timedelta(hours=2)

    def get_can_review(self, obj):
        return obj.status == Appointment.Status.COMPLETED and not hasattr(obj, 'review')

    def get_has_review(self, obj):
        return hasattr(obj, 'review')

class AppointmentStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=[
        Appointment.Status.CONFIRMED,
        Appointment.Status.COMPLETED,
        Appointment.Status.NO_SHOW,
        Appointment.Status.CANCELLED
    ])
    reason = serializers.CharField(required=False, allow_blank=True, default='')

class AppointmentRescheduleSerializer(serializers.Serializer):
    new_date = serializers.DateField(required=True)
    new_time_str = serializers.CharField(required=True, help_text="HH:MM masalan 15:00")

class FavoriteSerializer(serializers.ModelSerializer):
    barber_detail = BarberListSerializer(source='barber', read_only=True)

    class Meta:
        model = Favorite
        fields = ['id', 'barber', 'barber_detail', 'created_at']
        read_only_fields = ['id', 'created_at']
