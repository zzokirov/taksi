from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth.password_validation import validate_password
from .models import User, CustomerProfile, BarberProfile, Barbershop

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        user = self.user
        
        data['user'] = {
            'id': user.id,
            'phone_number': user.phone_number,
            'full_name': user.full_name,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'role': user.role,
            'email': user.email,
        }

        if user.role == User.Role.BARBER and hasattr(user, 'barber_profile'):
            profile = user.barber_profile
            data['user']['barber_profile'] = {
                'id': profile.id,
                'is_verified': profile.is_verified,
                'verification_status': profile.verification_status,
                'barbershop_name': profile.barbershop_name or (profile.barbershop.name if profile.barbershop else ''),
                'address': profile.address,
                'rating_avg': float(profile.rating_avg),
                'rating_count': profile.rating_count,
                'avatar': profile.avatar.url if profile.avatar else None,
            }
        elif user.role == User.Role.CUSTOMER and hasattr(user, 'customer_profile'):
            profile = user.customer_profile
            data['user']['customer_profile'] = {
                'id': profile.id,
                'avatar': profile.avatar.url if profile.avatar else None,
                'notification_enabled': profile.notification_enabled,
            }

        return data

class CustomerRegisterSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(write_only=True, required=True)
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True, required=True)
    terms_accepted = serializers.BooleanField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ['phone_number', 'email', 'full_name', 'password', 'password_confirm', 'terms_accepted']

    def validate(self, attrs):
        if not attrs.get('terms_accepted'):
            raise serializers.ValidationError({"terms_accepted": "Foydalanish shartlarini qabul qilishingiz shart!"})
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password_confirm": "Parollar bir xil emas!"})
        return attrs

    def create(self, validated_data):
        full_name = validated_data.pop('full_name')
        password = validated_data.pop('password')
        validated_data.pop('password_confirm')
        validated_data.pop('terms_accepted')

        names = full_name.strip().split(' ', 1)
        first_name = names[0]
        last_name = names[1] if len(names) > 1 else ''

        user = User.objects.create_user(
            phone_number=validated_data.get('phone_number'),
            password=password,
            first_name=first_name,
            last_name=last_name,
            email=validated_data.get('email', ''),
            role=User.Role.CUSTOMER
        )
        CustomerProfile.objects.create(user=user)
        return user

class BarberRegisterSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(write_only=True, required=True)
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True, required=True)
    barbershop_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    address = serializers.CharField(write_only=True, required=False, allow_blank=True)
    bio = serializers.CharField(write_only=True, required=False, allow_blank=True)
    experience_years = serializers.IntegerField(write_only=True, required=False, default=1)
    avatar = serializers.ImageField(write_only=True, required=False)

    class Meta:
        model = User
        fields = [
            'phone_number', 'email', 'full_name', 'password', 'password_confirm',
            'barbershop_name', 'address', 'bio', 'experience_years', 'avatar'
        ]

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password_confirm": "Parollar bir xil emas!"})
        return attrs

    def create(self, validated_data):
        full_name = validated_data.pop('full_name')
        password = validated_data.pop('password')
        validated_data.pop('password_confirm')
        
        barbershop_name = validated_data.pop('barbershop_name', '')
        address = validated_data.pop('address', '')
        bio = validated_data.pop('bio', '')
        experience_years = validated_data.pop('experience_years', 1)
        avatar = validated_data.pop('avatar', None)

        names = full_name.strip().split(' ', 1)
        first_name = names[0]
        last_name = names[1] if len(names) > 1 else ''

        user = User.objects.create_user(
            phone_number=validated_data.get('phone_number'),
            password=password,
            first_name=first_name,
            last_name=last_name,
            email=validated_data.get('email', ''),
            role=User.Role.BARBER
        )

        BarberProfile.objects.create(
            user=user,
            barbershop_name=barbershop_name,
            address=address,
            bio=bio,
            experience_years=experience_years,
            avatar=avatar,
            is_verified=False,
            verification_status=BarberProfile.VerificationStatus.PENDING
        )
        return user

class UserDetailSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(read_only=True)
    customer_profile = serializers.SerializerMethodField()
    barber_profile = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'phone_number', 'email', 'first_name', 'last_name',
            'full_name', 'role', 'customer_profile', 'barber_profile'
        ]

    def get_customer_profile(self, obj):
        if obj.role == User.Role.CUSTOMER and hasattr(obj, 'customer_profile'):
            profile = obj.customer_profile
            return {
                'id': profile.id,
                'avatar': profile.avatar.url if profile.avatar else None,
                'notification_enabled': profile.notification_enabled,
                'notes': profile.notes,
            }
        return None

    def get_barber_profile(self, obj):
        if obj.role == User.Role.BARBER and hasattr(obj, 'barber_profile'):
            profile = obj.barber_profile
            return {
                'id': profile.id,
                'is_verified': profile.is_verified,
                'verification_status': profile.verification_status,
                'barbershop_name': profile.barbershop_name or (profile.barbershop.name if profile.barbershop else ''),
                'address': profile.address,
                'bio': profile.bio,
                'experience_years': profile.experience_years,
                'rating_avg': float(profile.rating_avg),
                'rating_count': profile.rating_count,
                'avatar': profile.avatar.url if profile.avatar else None,
                'slot_interval_minutes': profile.slot_interval_minutes,
                'advance_booking_days': profile.advance_booking_days,
            }
        return None

class ChangePasswordSerializer(serializers.Serializer):
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(required=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({"new_password_confirm": "Yangi parollar mos kelmadi!"})
        return attrs
