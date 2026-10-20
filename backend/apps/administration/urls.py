from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'complaints', views.AdminComplaintViewSet, basename='admin-complaint')
router.register(r'subscription-plans', views.AdminSubscriptionPlanViewSet, basename='admin-subscription-plan')

urlpatterns = [
    path('stats/', views.AdminDashboardStatsView.as_view(), name='admin-stats'),
    path('pending-barbers/', views.AdminPendingBarbersListView.as_view(), name='admin-pending-barbers'),
    path('barbers/<int:pk>/verify/', views.AdminBarberVerificationView.as_view(), name='admin-verify-barber'),
    path('users/', views.AdminUsersListView.as_view(), name='admin-users-list'),
    path('users/<int:pk>/toggle-active/', views.AdminUserToggleActiveView.as_view(), name='admin-toggle-active'),
    path('audit-logs/', views.AdminAuditLogListView.as_view(), name='admin-audit-logs'),
    path('', include(router.urls)),
]
