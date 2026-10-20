from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'my-services', views.BarberServiceViewSet, basename='barber-service')
router.register(r'my-break-times', views.BarberBreakTimeViewSet, basename='barber-break-time')
router.register(r'my-blocked-slots', views.BarberBlockedSlotViewSet, basename='barber-blocked-slot')

urlpatterns = [
    # Customer-facing
    path('', views.BarberListView.as_view(), name='barber-list'),
    path('<int:pk>/', views.BarberDetailView.as_view(), name='barber-detail'),

    # Barber Dashboard Endpoints
    path('dashboard/overview/', views.BarberOverviewView.as_view(), name='barber-overview'),
    path('dashboard/working-hours/', views.BarberWorkingHoursView.as_view(), name='barber-working-hours'),
    path('dashboard/customers/', views.BarberCustomersView.as_view(), name='barber-customers'),
    path('dashboard/revenue-stats/', views.BarberRevenueStatsView.as_view(), name='barber-revenue-stats'),

    # Router endpoints (services, breaks, blocked slots)
    path('dashboard/', include(router.urls)),
]
