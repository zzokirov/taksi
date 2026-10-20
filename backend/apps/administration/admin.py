from django.contrib import admin
from .models import Complaint, SubscriptionPlan, Subscription, PaymentTransaction, AuditLog

@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = ('id', 'reporter', 'reported_user', 'reason', 'status', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('reporter__phone_number', 'reported_user__phone_number', 'reason', 'details')

@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ('name', 'price', 'duration_days', 'max_services', 'is_active')
    list_filter = ('is_active',)

@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ('barber', 'plan', 'start_date', 'end_date', 'is_active')
    list_filter = ('is_active', 'plan')

@admin.register(PaymentTransaction)
class PaymentTransactionAdmin(admin.ModelAdmin):
    list_display = ('id', 'amount', 'currency', 'status', 'payment_method', 'transaction_id', 'created_at')
    list_filter = ('status', 'payment_method')

@admin.register(AuditLog)
class AuditLogAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'action', 'ip_address', 'timestamp')
    search_fields = ('action', 'user__phone_number')
