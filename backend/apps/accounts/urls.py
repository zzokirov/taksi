from django.urls import path
from . import views

urlpatterns = [
    path('register/customer/', views.CustomerRegisterView.as_view(), name='register-customer'),
    path('register/barber/', views.BarberRegisterView.as_view(), name='register-barber'),
    path('login/', views.CustomTokenObtainPairView.as_view(), name='token-obtain-pair'),
    path('token/refresh/', views.CustomTokenRefreshView.as_view(), name='token-refresh'),
    path('me/', views.CurrentUserView.as_view(), name='current-user'),
    path('profile/customer/', views.CustomerProfileUpdateView.as_view(), name='update-customer-profile'),
    path('profile/barber/', views.BarberProfileUpdateView.as_view(), name='update-barber-profile'),
    path('change-password/', views.ChangePasswordView.as_view(), name='change-password'),
    path('fcm-token/', views.UpdateFCMTokenView.as_view(), name='update-fcm-token'),
]
