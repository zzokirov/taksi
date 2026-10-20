from django.db import models
from django.utils.translation import gettext_lazy as _
from apps.accounts.models import User, BarberProfile
from apps.appointments.models import Appointment

class Complaint(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', _('Ko\'rib chiqilmoqda (Pending)')
        INVESTIGATING = 'investigating', _('O\'rganilmoqda (Investigating)')
        RESOLVED = 'resolved', _('Hal qilindi (Resolved)')
        DISMISSED = 'dismissed', _('Rad etildi (Dismissed)')

    reporter = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='filed_complaints',
        verbose_name=_('Shikoyat qiluvchi')
    )
    reported_user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='complaints_against',
        verbose_name=_('Shikoyat qilingan shaxs')
    )
    appointment = models.ForeignKey(
        Appointment,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='complaints',
        verbose_name=_('Tegishli qabul')
    )
    reason = models.CharField(_('Shikoyat mavzusi/sababi'), max_length=255)
    details = models.TextField(_('Batafsil ma\'lumot'))
    status = models.CharField(
        _('Holati'),
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING
    )
    resolution_notes = models.TextField(_('Admin qarori va xulosasi'), blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('Shikoyat')
        verbose_name_plural = _('Shikoyatlar')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.reporter.full_name} -> {self.reported_user.full_name} ({self.status})"

class SubscriptionPlan(models.Model):
    name = models.CharField(_('Reja nomi'), max_length=100)
    description = models.TextField(_('Ta\'rif'), blank=True)
    price = models.DecimalField(_('Narxi (UZS)'), max_digits=12, decimal_places=0)
    duration_days = models.PositiveIntegerField(_('Amal qilish muddati (kun)'), default=30)
    max_services = models.PositiveIntegerField(_('Maksimal xizmatlar soni'), default=20)
    features = models.JSONField(_('Imkoniyatlar'), default=list, blank=True)
    is_active = models.BooleanField(_('Faol'), default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Obuna rejasi')
        verbose_name_plural = _('Obuna rejalari')

    def __str__(self):
        return f"{self.name} - {self.price:,} UZS ({self.duration_days} kun)"

class Subscription(models.Model):
    barber = models.ForeignKey(
        BarberProfile,
        on_delete=models.CASCADE,
        related_name='subscriptions',
        verbose_name=_('Sartarosh')
    )
    plan = models.ForeignKey(
        SubscriptionPlan,
        on_delete=models.CASCADE,
        related_name='subscriptions',
        verbose_name=_('Tarif')
    )
    start_date = models.DateField(_('Boshlanish sanasi'))
    end_date = models.DateField(_('Tugash sanasi'))
    is_active = models.BooleanField(_('Faol'), default=True)
    auto_renew = models.BooleanField(_('Avtomatik uzaytirish'), default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Sartarosh obunasi')
        verbose_name_plural = _('Sartarosh obunalari')
        ordering = ['-end_date']

    def __str__(self):
        return f"{self.barber.user.full_name} - {self.plan.name} ({self.start_date} - {self.end_date})"

class PaymentTransaction(models.Model):
    class Status(models.TextChoices):
        PENDING = 'pending', _('Kutilmoqda (Pending)')
        COMPLETED = 'completed', _('To\'landi (Completed)')
        FAILED = 'failed', _('Xatolik (Failed)')
        REFUNDED = 'refunded', _('Qaytarildi (Refunded)')

    class Method(models.TextChoices):
        CASH = 'cash', _('Naqd pul')
        CLICK = 'click', _('Click')
        PAYME = 'payme', _('Payme')
        CARD = 'card', _('Bank kartasi')

    appointment = models.ForeignKey(
        Appointment,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='transactions',
        verbose_name=_('Qabul')
    )
    barber = models.ForeignKey(
        BarberProfile,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='transactions',
        verbose_name=_('Sartarosh')
    )
    customer = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='transactions',
        verbose_name=_('Mijoz')
    )
    amount = models.DecimalField(_('Summa (UZS)'), max_digits=12, decimal_places=0)
    currency = models.CharField(_('Valyuta'), max_length=10, default='UZS')
    status = models.CharField(
        _('To\'lov holati'),
        max_length=20,
        choices=Status.choices,
        default=Status.COMPLETED
    )
    payment_method = models.CharField(
        _('To\'lov usuli'),
        max_length=20,
        choices=Method.choices,
        default=Method.CASH
    )
    transaction_id = models.CharField(_('Tranzaksiya ID'), max_length=100, unique=True, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('To\'lov tranzaksiyasi')
        verbose_name_plural = _('To\'lov tranzaksiyalari')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.amount:,} {self.currency} [{self.status}] ({self.payment_method})"

class AuditLog(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name=_('Foydalanuvchi')
    )
    action = models.CharField(_('Harakat'), max_length=255)
    ip_address = models.GenericIPAddressField(_('IP manzil'), null=True, blank=True)
    details = models.JSONField(_('Tafsilotlar'), default=dict, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Audit yozuvi')
        verbose_name_plural = _('Audit jurnali')
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.timestamp} - {self.user}: {self.action}"
