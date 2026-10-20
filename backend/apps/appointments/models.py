from django.db import models
from django.utils.translation import gettext_lazy as _
from django.core.exceptions import ValidationError
from apps.accounts.models import User, BarberProfile
from apps.barbers.models import Service

class Appointment(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', _('Kutilmoqda (Pending)')
        CONFIRMED = 'confirmed', _('Tasdiqlandi (Confirmed)')
        COMPLETED = 'completed', _('Yakunlandi (Completed)')
        CANCELLED = 'cancelled', _('Bekor qilindi (Cancelled)')
        NO_SHOW = 'no_show', _('Kelmadi (No-show)')

    customer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='appointments',
        verbose_name=_('Mijoz')
    )
    barber = models.ForeignKey(
        BarberProfile,
        on_delete=models.CASCADE,
        related_name='appointments',
        verbose_name=_('Sartarosh')
    )
    service = models.ForeignKey(
        Service,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='appointments',
        verbose_name=_('Xizmat')
    )
    
    # Historical immutable snapshot of service details
    service_name = models.CharField(_('Xizmat nomi (tarixiy)'), max_length=200)
    service_price = models.DecimalField(
        _('Xizmat narxi (UZS)'),
        max_digits=12,
        decimal_places=0
    )
    service_duration_minutes = models.PositiveIntegerField(
        _('Xizmat davomiyligi (daqiqa)'),
        default=30
    )

    appointment_date = models.DateField(_('Qabul sanasi'), db_index=True)
    start_time = models.TimeField(_('Boshlanish vaqti'))
    end_time = models.TimeField(_('Tugash vaqti'))

    status = models.CharField(
        _('Buyurtma holati'),
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True
    )
    notes = models.TextField(_('Mijoz eslatmasi'), blank=True)
    rejection_reason = models.TextField(_('Rad etish sababi'), blank=True)
    cancellation_reason = models.TextField(_('Bekor qilish sababi'), blank=True)
    cancelled_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='cancelled_appointments',
        verbose_name=_('Bekor qilgan foydalanuvchi')
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('Buyurtma / Qabul')
        verbose_name_plural = _('Buyurtmalar / Qabullar')
        ordering = ['-appointment_date', '-start_time']
        indexes = [
            models.Index(fields=['barber', 'appointment_date', 'status']),
            models.Index(fields=['customer', 'appointment_date']),
        ]

    def __str__(self):
        return f"{self.customer.full_name} -> {self.barber.user.full_name} ({self.appointment_date} {self.start_time}-{self.end_time}) [{self.status}]"

    def clean(self):
        if self.start_time and self.end_time and self.start_time >= self.end_time:
            raise ValidationError(_("Tugash vaqti boshlanish vaqtidan keyin bo'lishi kerak!"))

class Favorite(models.Model):
    customer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='favorites',
        verbose_name=_('Mijoz')
    )
    barber = models.ForeignKey(
        BarberProfile,
        on_delete=models.CASCADE,
        related_name='favorited_by',
        verbose_name=_('Sartarosh')
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Sevimli sartarosh')
        verbose_name_plural = _('Sevimli sartaroshlar')
        unique_together = ('customer', 'barber')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.customer.full_name} -> {self.barber.user.full_name}"
