from django.contrib import admin
from .models import Appointment, Favorite

@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ('id', 'customer', 'barber', 'service_name', 'service_price', 'appointment_date', 'start_time', 'status')
    list_filter = ('status', 'appointment_date')
    search_fields = ('customer__phone_number', 'customer__first_name', 'barber__user__phone_number', 'barber__user__first_name')

@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ('customer', 'barber', 'created_at')
