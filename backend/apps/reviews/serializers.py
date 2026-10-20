from rest_framework import serializers
from .models import Review
from apps.appointments.models import Appointment

class ReviewSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    customer_avatar = serializers.SerializerMethodField()
    formatted_date = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = [
            'id', 'appointment', 'customer', 'customer_name', 'customer_avatar',
            'barber', 'rating', 'comment', 'formatted_date', 'created_at'
        ]
        read_only_fields = ['id', 'customer', 'barber', 'created_at']

    def get_customer_avatar(self, obj):
        if hasattr(obj.customer, 'customer_profile') and obj.customer.customer_profile.avatar:
            return obj.customer.customer_profile.avatar.url
        return None

    def get_formatted_date(self, obj):
        return obj.created_at.strftime('%d.%m.%Y')

class ReviewCreateSerializer(serializers.ModelSerializer):
    appointment_id = serializers.IntegerField(write_only=True)

    class Meta:
        model = Review
        fields = ['appointment_id', 'rating', 'comment']

    def validate(self, attrs):
        user = self.context['request'].user
        appt_id = attrs.get('appointment_id')

        try:
            appointment = Appointment.objects.get(id=appt_id, customer=user)
        except Appointment.DoesNotExist:
            raise serializers.ValidationError({"appointment_id": "Buyurtma topilmadi yoki bu sizning buyurtmangiz emas!"})

        if appointment.status != Appointment.Status.COMPLETED:
            raise serializers.ValidationError({"appointment_id": "Faqat yakunlangan (completed) qabullar uchun sharh qoldirish mumkin!"})

        if hasattr(appointment, 'review'):
            raise serializers.ValidationError({"appointment_id": "Ushbu qabul uchun allaqachon sharh qoldirilgan!"})

        attrs['appointment_obj'] = appointment
        return attrs

    def create(self, validated_data):
        appointment = validated_data['appointment_obj']
        customer = self.context['request'].user
        rating = validated_data['rating']
        comment = validated_data.get('comment', '')

        review = Review.objects.create(
            appointment=appointment,
            customer=customer,
            barber=appointment.barber,
            rating=rating,
            comment=comment
        )
        return review
