from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, CustomerProfile, BarberProfile, Barbershop

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('phone_number', 'first_name', 'last_name', 'role', 'is_active', 'date_joined')
    list_filter = ('role', 'is_active', 'date_joined')
    search_fields = ('phone_number', 'first_name', 'last_name', 'email')
    ordering = ('-date_joined',)
    fieldsets = (
        (None, {'fields': ('phone_number', 'password')}),
        ('Shaxsiy ma\'lumotlar', {'fields': ('first_name', 'last_name', 'email', 'role')}),
        ('Ruxsatlar', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Sanalar', {'fields': ('last_login', 'date_joined')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('phone_number', 'role', 'first_name', 'last_name', 'password'),
        }),
    )

@admin.register(CustomerProfile)
class CustomerProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'notification_enabled', 'created_at')
    search_fields = ('user__phone_number', 'user__first_name', 'user__last_name')

@admin.register(BarberProfile)
class BarberProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'barbershop_name', 'is_verified', 'verification_status', 'rating_avg', 'rating_count')
    list_filter = ('verification_status', 'is_verified')
    search_fields = ('user__phone_number', 'user__first_name', 'user__last_name', 'barbershop_name')

@admin.register(Barbershop)
class BarbershopAdmin(admin.ModelAdmin):
    list_display = ('name', 'city', 'phone', 'is_active', 'created_at')
    list_filter = ('city', 'is_active')
    search_fields = ('name', 'address', 'city')
