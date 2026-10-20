from django.db import models
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.utils.translation import gettext_lazy as _

class UserManager(BaseUserManager):
    def create_user(self, phone_number, password=None, **extra_fields):
        if not phone_number:
            raise ValueError(_("Telefon raqami kiritilishi shart!"))
        phone_number = phone_number.strip().replace(" ", "").replace("-", "")
        extra_fields.setdefault('is_active', True)
        user = self.model(phone_number=phone_number, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', User.Role.ADMIN)

        if extra_fields.get('is_staff') is not True:
            raise ValueError(_('Superuser is_staff=True bolishi kerak.'))
        if extra_fields.get('is_superuser') is not True:
            raise ValueError(_('Superuser is_superuser=True bolishi kerak.'))

        return self.create_user(phone_number, password, **extra_fields)

class User(AbstractUser):
    class Role(models.TextChoices):
        CUSTOMER = 'CUSTOMER', _('Mijoz (Customer)')
        BARBER = 'BARBER', _('Sartarosh (Barber)')
        ADMIN = 'ADMIN', _('Administrator')

    username = None
    phone_number = models.CharField(
        _('Telefon raqami'),
        max_length=20,
        unique=True,
        help_text=_('Masalan: +998901234567')
    )
    role = models.CharField(
        _('Foydalanuvchi roli'),
        max_length=20,
        choices=Role.choices,
        default=Role.CUSTOMER
    )
    email = models.EmailField(_('Email manzili'), blank=True, null=True)

    objects = UserManager()

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['first_name']

    class Meta:
        verbose_name = _('Foydalanuvchi')
        verbose_name_plural = _('Foydalanuvchilar')
        ordering = ['-date_joined']

    def __str__(self):
        name = self.get_full_name() or self.first_name or self.phone_number
        return f"{name} ({self.role})"

    @property
    def full_name(self):
        name = f"{self.first_name} {self.last_name}".strip()
        return name if name else self.phone_number

class Barbershop(models.Model):
    name = models.CharField(_('Sartaroshxona nomi'), max_length=255)
    address = models.CharField(_('Manzil'), max_length=500)
    city = models.CharField(_('Shahar'), max_length=100, default='Toshkent')
    latitude = models.FloatField(_('Kenglik (Latitude)'), null=True, blank=True)
    longitude = models.FloatField(_('Uzunlik (Longitude)'), null=True, blank=True)
    phone = models.CharField(_('Telefon raqami'), max_length=30, blank=True)
    description = models.TextField(_('Tavsif'), blank=True)
    logo = models.ImageField(_('Logo'), upload_to='barbershops/logos/', null=True, blank=True)
    cover_image = models.ImageField(_('Muqova rasmi'), upload_to='barbershops/covers/', null=True, blank=True)
    is_active = models.BooleanField(_('Faol'), default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Sartaroshxona')
        verbose_name_plural = _('Sartaroshxonalar')

    def __str__(self):
        return f"{self.name} - {self.city}"

class BarberProfile(models.Model):
    class VerificationStatus(models.TextChoices):
        PENDING = 'pending', _('Kutilmoqda (Pending)')
        APPROVED = 'approved', _('Tasdiqlangan (Approved)')
        REJECTED = 'rejected', _('Rad etilgan (Rejected)')

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='barber_profile')
    barbershop = models.ForeignKey(
        Barbershop,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='barbers'
    )
    barbershop_name = models.CharField(_('Sartaroshxona nomi (shaxsiy)'), max_length=255, blank=True)
    address = models.CharField(_('Ish manzili'), max_length=500, blank=True)
    bio = models.TextField(_('Sartarosh haqida ma\'lumot'), blank=True)
    avatar = models.ImageField(_('Rasm'), upload_to='barbers/avatars/', null=True, blank=True)
    experience_years = models.PositiveIntegerField(_('Tajriba (yil)'), default=1)
    
    # Administrator verification fields
    is_verified = models.BooleanField(_('Tasdiqlanganmi'), default=False)
    verification_status = models.CharField(
        _('Tasdiqlash holati'),
        max_length=20,
        choices=VerificationStatus.choices,
        default=VerificationStatus.PENDING
    )
    verification_notes = models.TextField(_('Admin eslatmasi/sababi'), blank=True)
    
    # Performance & stats
    rating_avg = models.DecimalField(_('O\'rtacha reyting'), max_digits=3, decimal_places=2, default=0.0)
    rating_count = models.PositiveIntegerField(_('Baholar soni'), default=0)
    
    # Booking configuration
    slot_interval_minutes = models.PositiveIntegerField(_('Qabul oralig\'i (daqiqa)'), default=30)
    advance_booking_days = models.PositiveIntegerField(_('Oldindan yozilish (kun)'), default=14)
    
    # Device notification token
    fcm_token = models.CharField(_('FCM Token'), max_length=255, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('Sartarosh profili')
        verbose_name_plural = _('Sartarosh profillari')

    def __str__(self):
        return f"{self.user.full_name} ({self.verification_status})"

class CustomerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='customer_profile')
    avatar = models.ImageField(_('Rasm'), upload_to='customers/avatars/', null=True, blank=True)
    notes = models.TextField(_('Mijoz eslatmasi'), blank=True)
    date_of_birth = models.DateField(_('Tug\'ilgan sana'), null=True, blank=True)
    fcm_token = models.CharField(_('FCM Token'), max_length=255, blank=True)
    notification_enabled = models.BooleanField(_('Bildirishnomalar yoqilgan'), default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Mijoz profili')
        verbose_name_plural = _('Mijoz profillari')

    def __str__(self):
        return f"{self.user.full_name}"
