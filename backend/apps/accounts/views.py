from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User, CustomerProfile, BarberProfile
from .serializers import (
    CustomerRegisterSerializer,
    BarberRegisterSerializer,
    CustomTokenObtainPairSerializer,
    UserDetailSerializer,
    ChangePasswordSerializer
)

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

class CustomTokenRefreshView(TokenRefreshView):
    pass

class CustomerRegisterView(generics.CreateAPIView):
    serializer_class = CustomerRegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Issue JWT tokens directly upon registration
        refresh = RefreshToken.for_user(user)
        user_data = UserDetailSerializer(user).data
        
        return Response({
            'message': 'Mijoz muvaffaqiyatli ro\'yxatdan o\'tdi',
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': user_data
        }, status=status.HTTP_201_CREATED)

class BarberRegisterView(generics.CreateAPIView):
    serializer_class = BarberRegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        refresh = RefreshToken.for_user(user)
        user_data = UserDetailSerializer(user).data

        return Response({
            'message': 'Sartarosh ro\'yxatdan o\'tdi. Profil administrator tasdig\'i kutilmoqda.',
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': user_data
        }, status=status.HTTP_201_CREATED)

class CurrentUserView(generics.RetrieveAPIView):
    serializer_class = UserDetailSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user

class CustomerProfileUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request):
        user = request.user
        if user.role != User.Role.CUSTOMER:
            return Response({'error': 'Faqat mijoz profili yangilanishi mumkin'}, status=status.HTTP_403_FORBIDDEN)
        
        profile, _ = CustomerProfile.objects.get_or_create(user=user)
        
        first_name = request.data.get('first_name')
        last_name = request.data.get('last_name')
        if first_name is not None:
            user.first_name = first_name
        if last_name is not None:
            user.last_name = last_name
        user.save()

        if 'notes' in request.data:
            profile.notes = request.data['notes']
        if 'notification_enabled' in request.data:
            profile.notification_enabled = request.data['notification_enabled']
        if 'avatar' in request.FILES:
            profile.avatar = request.FILES['avatar']
        profile.save()

        return Response(UserDetailSerializer(user).data)

class BarberProfileUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request):
        user = request.user
        if user.role != User.Role.BARBER:
            return Response({'error': 'Faqat sartarosh profili yangilanishi mumkin'}, status=status.HTTP_403_FORBIDDEN)

        profile, _ = BarberProfile.objects.get_or_create(user=user)

        first_name = request.data.get('first_name')
        last_name = request.data.get('last_name')
        if first_name is not None:
            user.first_name = first_name
        if last_name is not None:
            user.last_name = last_name
        user.save()

        fields = ['barbershop_name', 'address', 'bio', 'experience_years', 'slot_interval_minutes', 'advance_booking_days']
        for field in fields:
            if field in request.data:
                setattr(profile, field, request.data[field])

        if 'avatar' in request.FILES:
            profile.avatar = request.FILES['avatar']

        profile.save()
        return Response(UserDetailSerializer(user).data)

class ChangePasswordView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return Response({'old_password': ['Amaldagi parol noto\'g\'ri!']}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(serializer.validated_data['new_password'])
        user.save()
        return Response({'message': 'Parol muvaffaqiyatli o\'zgartirildi.'})

class UpdateFCMTokenView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        fcm_token = request.data.get('fcm_token')
        if not fcm_token:
            return Response({'error': 'fcm_token talab qilinadi'}, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        if hasattr(user, 'customer_profile'):
            user.customer_profile.fcm_token = fcm_token
            user.customer_profile.save(update_fields=['fcm_token'])
        elif hasattr(user, 'barber_profile'):
            user.barber_profile.fcm_token = fcm_token
            user.barber_profile.save(update_fields=['fcm_token'])

        return Response({'message': 'FCM token saqlandi'})
