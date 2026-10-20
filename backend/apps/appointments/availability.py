from datetime import date, datetime, time, timedelta
from django.utils import timezone
from apps.barbers.models import WorkingHours, BreakTime, BlockedTimeSlot, DayOfWeek
from .models import Appointment

def get_available_slots(barber, target_date, service_duration_minutes=30):
    """
    Calculates free time slots for a given barber on target_date.
    Takes into account:
    - Barber working hours for that day of week
    - Break times
    - Blocked time slots
    - Existing pending/confirmed appointments
    - Service duration (slot must fit the full duration before closing or next booking)
    - Past time slots if target_date is today
    """
    if isinstance(target_date, str):
        target_date = datetime.strptime(target_date, '%Y-%m-%d').date()

    today = timezone.localdate()
    now_time = timezone.localtime().time()

    # Cannot book in the past
    if target_date < today:
        return []

    # Check advance booking window
    max_date = today + timedelta(days=barber.advance_booking_days)
    if target_date > max_date:
        return []

    day_of_week = target_date.weekday() # 0 = Monday, 6 = Sunday

    # 1. Fetch Working Hours
    try:
        working_hour = WorkingHours.objects.get(barber=barber, day_of_week=day_of_week)
    except WorkingHours.DoesNotExist:
        # Default fallback
        if day_of_week == 6: # Sunday off by default
            return []
        start_time = time(9, 0)
        end_time = time(19, 0)
        is_working_day = True
    else:
        if not working_hour.is_working_day:
            return []
        start_time = working_hour.start_time
        end_time = working_hour.end_time

    # 2. Fetch Breaks
    breaks = BreakTime.objects.filter(barber=barber, day_of_week=day_of_week)

    # 3. Fetch Blocked Slots for this day
    day_start_dt = timezone.make_aware(datetime.combine(target_date, time.min))
    day_end_dt = timezone.make_aware(datetime.combine(target_date, time.max))
    blocked_slots = BlockedTimeSlot.objects.filter(
        barber=barber,
        start_datetime__lt=day_end_dt,
        end_datetime__gt=day_start_dt
    )

    # 4. Fetch Active Appointments (pending or confirmed)
    appointments = Appointment.objects.filter(
        barber=barber,
        appointment_date=target_date,
        status__in=[Appointment.Status.PENDING, Appointment.Status.CONFIRMED]
    )

    # 5. Generate candidate slots
    interval_minutes = barber.slot_interval_minutes or 30
    duration_delta = timedelta(minutes=service_duration_minutes)

    slots = []
    current_dt = datetime.combine(target_date, start_time)
    closing_dt = datetime.combine(target_date, end_time)

    while current_dt + duration_delta <= closing_dt:
        slot_start_time = current_dt.time()
        slot_end_time = (current_dt + duration_delta).time()

        # If today, cannot book earlier than current local time + 15 mins buffer
        if target_date == today:
            buffer_time = (timezone.localtime() + timedelta(minutes=15)).time()
            if slot_start_time < buffer_time:
                current_dt += timedelta(minutes=interval_minutes)
                continue

        # Check conflict with breaks
        is_conflict = False
        for brk in breaks:
            # Overlap condition: start < brk_end and end > brk_start
            if slot_start_time < brk.end_time and slot_end_time > brk.start_time:
                is_conflict = True
                break

        # Check conflict with blocked slots
        if not is_conflict:
            slot_start_aware = timezone.make_aware(datetime.combine(target_date, slot_start_time))
            slot_end_aware = timezone.make_aware(datetime.combine(target_date, slot_end_time))
            for bslot in blocked_slots:
                if slot_start_aware < bslot.end_datetime and slot_end_aware > bslot.start_datetime:
                    is_conflict = True
                    break

        # Check conflict with existing appointments
        if not is_conflict:
            for appt in appointments:
                if slot_start_time < appt.end_time and slot_end_time > appt.start_time:
                    is_conflict = True
                    break

        if not is_conflict:
            slots.append({
                'start_time': slot_start_time.strftime('%H:%M'),
                'end_time': slot_end_time.strftime('%H:%M'),
            })

        current_dt += timedelta(minutes=interval_minutes)

    return slots
