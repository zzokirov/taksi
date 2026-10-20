from django.db import models
from django.utils.translation import gettext_lazy as _
from apps.accounts.models import User, BarberProfile
from apps.appointments.models import Appointment

class Review(models.Model):
    appointment = models.OneToOneField(
        Appointment,
        on_delete=models.CASCADE,
        related_name='review',
        verbose_name=_('Qabul / Buyurtma')
    )
    customer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='reviews',
        verbose_name=_('Mijoz')
    )
    barber = models.ForeignKey(
        BarberProfile,
        on_delete=models.CASCADE,
        related_name='reviews',
        verbose_name=_('Sartarosh')
    )
    rating = models.PositiveSmallIntegerField(
        _('Baho (1-5)'),
        choices=[(i, f"{i} yulduz") for i in range(1, 6)],
        default=5
    )
    comment = models.TextField(_('Fikr-mulohaza'), blank=True)
    is_moderated = models.BooleanField(_('Moderatsiyadan o\'tgan'), default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Sharh / Fikr')
        verbose_name_plural = _('Sharhlar / Fikrlar')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.customer.full_name} -> {self.barber.user.full_name} ({self.rating}★)"

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        # Recalculate average rating for barber
        reviews = Review.objects.filter(barber=self.barber, is_moderated=True)
        count = reviews.count()
        if count > 0:
            avg = sum(r.rating for r in reviews) / count
            self.barber.rating_avg = round(avg, 2)
            self.barber.rating_count = count
        else:
            self.barber.rating_avg = 0.0
            self.barber.rating_count = 0
        self.barber.save(update_fields=['rating_avg', 'rating_count'])
