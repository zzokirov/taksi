from django.urls import path
from . import dashboard_views

urlpatterns = [
    path('', dashboard_views.dashboard_home, name='dash-home'),
    path('barbers/', dashboard_views.barbers_list, name='dash-barbers'),
    path('barbers/<int:pk>/verify/', dashboard_views.verify_barber_action, name='dash-barber-verify'),
    path('appointments/', dashboard_views.appointments_list, name='dash-appointments'),
    path('users/', dashboard_views.users_list, name='dash-users'),
    path('users/<int:pk>/toggle-active/', dashboard_views.toggle_user_active, name='dash-user-toggle'),
    path('complaints/', dashboard_views.complaints_list, name='dash-complaints'),
]
