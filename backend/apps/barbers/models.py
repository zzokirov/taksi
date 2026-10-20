from django.db import models
from django.utils.translation import gettext_lazy as _
from apps.accounts.models import BarberProfile, Barbershop

class DayOfWeek(models.IntegerChoices):
    MONDAY = 0, _('Dushanba')
    TUESDAY = 1, _('Seshanba')
    WEDNESDAY = 2, _('Chorshanba')
    THURSDAY = 3, _('Payshanba')
    FRIDAY = 4, _('Juma')
    SATURDAY = 5, _('Shanba')
    SUNDAY = 6, _('Yakshanba')

class Service(models.Model):
    barber = models.ForeignKey(
        BarberProfile,
        on_delete=models.CASCADE,
        related_name='services',
        verbose_name=_('Sartarosh')
    )
    barbershop = models.ForeignKey(
        Barbershop,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='services',
        verbose_name=_('Sartaroshxona')
    )
    name = models.CharField(_('Xizmat nomi'), max_length=200)
    description = models.TextField(_('Xizmat tavsifi'), blank=True)
    price = models.DecimalField(
        _('Narxi (UZS)'),
        max_digits=12,
        decimal_places=0,
        help_text=_('Masalan: 60000')
    )
    duration_minutes = models.PositiveIntegerField(
        _('Davomiyligi (daqiqa)'),
        default=30,
        help_text=_('Masalan: 30, 45, 60')
    )
    is_active = models.BooleanField(_('Faol xizmat'), default=True)
    image = models.ImageField(_('Xizmat rasmi'), upload_to='services/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('Xizmat')
        verbose_name_plural = _('Xizmatlar')
        ordering = ['price']

    def __str__(self):
        return f"{self.name} - {self.price:,} UZS ({self.duration_minutes} daq.)"

class WorkingHours(models.Model):
    barber = models.ForeignKey(
        BarberProfile,
        on_delete=models.CASCADE,
        related_name='working_hours',
        verbose_name=_('Sartarosh')
    )
    day_of_week = models.IntegerField(_('Hafta kuni'), choices=DayOfWeek.choices)
    is_working_day = models.BooleanField(_('Ish kuni'), default=True)
    start_time = models.TimeField(_('Ish boshlanishi'), default='09:00:00')
    end_time = models.TimeField(_('Ish tugashi'), default='19:00:00')

    class Meta:
        verbose_name = _('Ish vaqti')
        verbose_name_plural = _('Ish vaqtlari')
        unique_together = ('barber', 'day_of_week')
        ordering = ['day_of_week']

    def __str__(self):
        day_name = DayOfWeek(self.day_of_week).label
        if not self.is_working_day:
            return f"{self.barber.user.full_name}: {day_name} (Dam olish kuni)"
        return f"{self.barber.user.full_name}: {day_name} ({self.start_time} - {self.end_time})"

class BreakTime(models.Model):
    barber = models.ForeignKey(
        BarberProfile,
        on_delete=models.CASCADE,
        related_name='break_times',
        verbose_name=_('Sartarosh')
    )
    day_of_week = models.IntegerField(_('Hafta kuni'), choices=DayOfWeek.choices)
    start_time = models.TimeField(_('Tanaffus boshlanishi'), default='13:00:00')
    end_time = models.TimeField(_('Tanaffus tugashi'), default='14:00:00')
    title = models.CharField(_('Tanaffus nomi'), max_length=100, default='Tushlik')

    class Meta:
        verbose_name = _('Tanaffus vaqti')
        verbose_name_plural = _('Tanaffus vaqtlari')
        ordering = ['day_of_week', 'start_time']

    def __str__(self):
        day_name = DayOfWeek(self.day_of_week).label
        return f"{self.barber.user.full_name}: {day_name} {self.title} ({self.start_time} - {self.end_time})"

class BlockedTimeSlot(models.Model):
    barber = models.ForeignKey(
        BarberProfile,
        on_delete=models.CASCADE,
        related_name='blocked_slots',
        verbose_name=_('Sartarosh')
    )
    start_datetime = models.DateTimeField(_('Boshlanish vaqti'))
    end_datetime = models.DateTimeField(_('Tugash vaqti'))
    reason = models.CharField(_('Band qilish sababi'), max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Band qilingan vaqt oralig\'i')
        verbose_name_plural = _('Band qilingan vaqt oraliqlari')
        ordering = ['start_datetime']

    def __str__(self):
        return f"{self.barber.user.full_name} ({self.start_datetime} - {self.end_datetime}): {self.reason}"
