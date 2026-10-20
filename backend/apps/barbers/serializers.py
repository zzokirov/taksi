from rest_framework import serializers
from .models import Service, WorkingHours, BreakTime, BlockedTimeSlot, DayOfWeek
from apps.accounts.models import BarberProfile, Barbershop, User

class ServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Service
        fields = [
            'id', 'barber', 'barbershop', 'name', 'description',
            'price', 'duration_minutes', 'is_active', 'image',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'barber', 'created_at', 'updated_at']

    def create(self, validated_data):
        # Automatically assign logged in barber's profile
        request = self.context.get('request')
        if request and hasattr(request.user, 'barber_profile'):
            validated_data['barber'] = request.user.barber_profile
        return super().create(validated_data)

class WorkingHoursSerializer(serializers.ModelSerializer):
    day_name = serializers.SerializerMethodField()

    class Meta:
        model = WorkingHours
        fields = ['id', 'barber', 'day_of_week', 'day_name', 'is_working_day', 'start_time', 'end_time']
        read_only_fields = ['id', 'barber', 'day_name']

    def get_day_name(self, obj):
        try:
            return DayOfWeek(obj.day_of_week).label
        except Exception:
            return str(obj.day_of_week)

class BreakTimeSerializer(serializers.ModelSerializer):
    day_name = serializers.SerializerMethodField()

    class Meta:
        model = BreakTime
        fields = ['id', 'barber', 'day_of_week', 'day_name', 'start_time', 'end_time', 'title']
        read_only_fields = ['id', 'barber', 'day_name']

    def get_day_name(self, obj):
        try:
            return DayOfWeek(obj.day_of_week).label
        except Exception:
            return str(obj.day_of_week)

class BlockedTimeSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = BlockedTimeSlot
        fields = ['id', 'barber', 'start_datetime', 'end_datetime', 'reason', 'created_at']
        read_only_fields = ['id', 'barber', 'created_at']

class BarberListSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='user.full_name', read_only=True)
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    barbershop_name_display = serializers.SerializerMethodField()
    services_count = serializers.SerializerMethodField()
    min_price = serializers.SerializerMethodField()
    is_favorite = serializers.SerializerMethodField()

    class Meta:
        model = BarberProfile
        fields = [
            'id', 'user_id', 'full_name', 'phone_number', 'barbershop_name_display',
            'address', 'bio', 'avatar', 'experience_years', 'is_verified',
            'verification_status', 'rating_avg', 'rating_count',
            'slot_interval_minutes', 'advance_booking_days',
            'services_count', 'min_price', 'is_favorite'
        ]

    def get_barbershop_name_display(self, obj):
        if obj.barbershop:
            return obj.barbershop.name
        return obj.barbershop_name or "Mustaqil sartarosh"

    def get_services_count(self, obj):
        return obj.services.filter(is_active=True).count()

    def get_min_price(self, obj):
        active_services = obj.services.filter(is_active=True)
        if active_services.exists():
            return int(min(s.price for s in active_services))
        return 0

    def get_is_favorite(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.favorited_by.filter(customer=request.user).exists()
        return False

class BarberDetailSerializer(BarberListSerializer):
    services = serializers.SerializerMethodField()
    working_hours = WorkingHoursSerializer(many=True, read_only=True)
    break_times = BreakTimeSerializer(many=True, read_only=True)

    class Meta(BarberListSerializer.Meta):
        fields = BarberListSerializer.Meta.fields + ['services', 'working_hours', 'break_times']

    def get_services(self, obj):
        services = obj.services.filter(is_active=True)
        return ServiceSerializer(services, many=True, context=self.context).data
