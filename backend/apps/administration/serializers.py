from rest_framework import serializers
from .models import Complaint, SubscriptionPlan, Subscription, PaymentTransaction, AuditLog
from apps.accounts.models import BarberProfile, User
from apps.appointments.models import Appointment

class ComplaintSerializer(serializers.ModelSerializer):
    reporter_name = serializers.CharField(source='reporter.full_name', read_only=True)
    reported_user_name = serializers.CharField(source='reported_user.full_name', read_only=True)

    class Meta:
        model = Complaint
        fields = [
            'id', 'reporter', 'reporter_name', 'reported_user', 'reported_user_name',
            'appointment', 'reason', 'details', 'status', 'resolution_notes',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'reporter', 'created_at', 'updated_at']

class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = '__all__'

class SubscriptionSerializer(serializers.ModelSerializer):
    barber_name = serializers.CharField(source='barber.user.full_name', read_only=True)
    plan_name = serializers.CharField(source='plan.name', read_only=True)

    class Meta:
        model = Subscription
        fields = '__all__'

class PaymentTransactionSerializer(serializers.ModelSerializer):
    barber_name = serializers.CharField(source='barber.user.full_name', read_only=True)
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)

    class Meta:
        model = PaymentTransaction
        fields = '__all__'

class AuditLogSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.full_name', read_only=True)

    class Meta:
        model = AuditLog
        fields = '__all__'

class BarberVerificationSerializer(serializers.Serializer):
    status = serializers.ChoiceField(choices=['approved', 'rejected'])
    notes = serializers.CharField(required=False, allow_blank=True, default='')
