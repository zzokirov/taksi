from django.db import models
from django.utils.translation import gettext_lazy as _
from apps.accounts.models import User

class Notification(models.Model):
    class NotificationType(models.TextChoices):
        BOOKING_CREATED = 'booking_created', _('Yangi buyurtma (Booking Created)')
        BOOKING_CONFIRMED = 'booking_confirmed', _('Buyurtma tasdiqlandi (Confirmed)')
        BOOKING_REJECTED = 'booking_rejected', _('Buyurtma rad etildi (Rejected)')
        BOOKING_CANCELLED = 'booking_cancelled', _('Buyurtma bekor qilindi (Cancelled)')
        BOOKING_RESCHEDULED = 'booking_rescheduled', _('Vaqti o\'zgartirildi (Rescheduled)')
        SYSTEM = 'system', _('Tizim xabari (System)')

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name=_('Foydalanuvchi')
    )
    title = models.CharField(_('Sarlavha'), max_length=200)
    body = models.TextField(_('Xabar matni'))
    notification_type = models.CharField(
        _('Xabar turi'),
        max_length=30,
        choices=NotificationType.choices,
        default=NotificationType.SYSTEM
    )
    is_read = models.BooleanField(_('O\'qilgan'), default=False)
    data = models.JSONField(_('Qo\'shimcha ma\'lumotlar'), default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Bildirishnoma')
        verbose_name_plural = _('Bildirishnomalar')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.full_name}: {self.title} ({'O\'qilgan' if self.is_read else 'Yangi'})"
