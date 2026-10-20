from django.contrib import admin
from .models import Service, WorkingHours, BreakTime, BlockedTimeSlot

@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ('name', 'barber', 'price', 'duration_minutes', 'is_active')
    list_filter = ('is_active', 'duration_minutes')
    search_fields = ('name', 'barber__user__first_name', 'barber__user__last_name')

@admin.register(WorkingHours)
class WorkingHoursAdmin(admin.ModelAdmin):
    list_display = ('barber', 'day_of_week', 'is_working_day', 'start_time', 'end_time')
    list_filter = ('day_of_week', 'is_working_day')

@admin.register(BreakTime)
class BreakTimeAdmin(admin.ModelAdmin):
    list_display = ('barber', 'day_of_week', 'title', 'start_time', 'end_time')

@admin.register(BlockedTimeSlot)
class BlockedTimeSlotAdmin(admin.ModelAdmin):
    list_display = ('barber', 'start_datetime', 'end_datetime', 'reason')
