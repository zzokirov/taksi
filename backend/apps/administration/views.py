from django.db.models import Count, Sum
from django.utils import timezone
from rest_framework import generics, permissions, status, viewsets
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Complaint, SubscriptionPlan, Subscription, PaymentTransaction, AuditLog
from .serializers import (
    ComplaintSerializer,
    SubscriptionPlanSerializer,
    SubscriptionSerializer,
    PaymentTransactionSerializer,
    AuditLogSerializer,
    BarberVerificationSerializer
)
from apps.accounts.models import BarberProfile, User
from apps.accounts.serializers import UserDetailSerializer
from apps.barbers.serializers import BarberListSerializer
from apps.appointments.models import Appointment
from apps.appointments.serializers import AppointmentListSerializer
from apps.core.permissions import IsAdminRole
from apps.notifications.models import Notification

class AdminDashboardStatsView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def get(self, request):
        total_users = User.objects.count()
        total_customers = User.objects.filter(role=User.Role.CUSTOMER).count()
        total_barbers = User.objects.filter(role=User.Role.BARBER).count()
        pending_barbers = BarberProfile.objects.filter(verification_status='pending').count()
        
        total_appointments = Appointment.objects.count()
        completed_appointments = Appointment.objects.filter(status=Appointment.Status.COMPLETED).count()
        total_revenue = Appointment.objects.filter(status=Appointment.Status.COMPLETED).aggregate(
            t=Sum('service_price')
        )['t'] or 0

        pending_complaints = Complaint.objects.filter(status='pending').count()

        return Response({
            'total_users': total_users,
            'total_customers': total_customers,
            'total_barbers': total_barbers,
            'pending_barbers_count': pending_barbers,
            'total_appointments': total_appointments,
            'completed_appointments': completed_appointments,
            'total_revenue_uzs': int(total_revenue),
            'pending_complaints_count': pending_complaints,
        })

class AdminBarberVerificationView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def post(self, request, pk):
        try:
            barber = BarberProfile.objects.get(id=pk)
        except BarberProfile.DoesNotExist:
            return Response({"error": "Sartarosh topilmadi"}, status=status.HTTP_404_NOT_FOUND)

        serializer = BarberVerificationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_status = serializer.validated_data['status']
        notes = serializer.validated_data.get('notes', '')

        barber.verification_status = new_status
        barber.is_verified = (new_status == 'approved')
        barber.verification_notes = notes
        barber.save()

        # Create audit log
        AuditLog.objects.create(
            user=request.user,
            action=f"Barber verification: {barber.user.full_name} -> {new_status}",
            details={'barber_id': barber.id, 'status': new_status, 'notes': notes}
        )

        # Notify barber
        Notification.objects.create(
            user=barber.user,
            title="Profil tasdiqlandi!" if barber.is_verified else "Profil rad etildi",
            body="Tabriklaymiz! Sizning sartarosh profilingiz tasdiqlandi va mijozlar uchun ochiq." if barber.is_verified else f"Profilingiz rad etildi. Sabab: {notes}",
            notification_type=Notification.NotificationType.SYSTEM
        )

        return Response(BarberListSerializer(barber).data)

class AdminPendingBarbersListView(generics.ListAPIView):
    serializer_class = BarberListSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def get_queryset(self):
        return BarberProfile.objects.filter(verification_status='pending').select_related('user')

class AdminUsersListView(generics.ListAPIView):
    serializer_class = UserDetailSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def get_queryset(self):
        role = self.request.query_params.get('role')
        qs = User.objects.all().order_by('-date_joined')
        if role:
            qs = qs.filter(role=role)
        return qs

class AdminUserToggleActiveView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def post(self, request, pk):
        try:
            user = User.objects.get(id=pk)
        except User.DoesNotExist:
            return Response({"error": "Foydalanuvchi topilmadi"}, status=status.HTTP_404_NOT_FOUND)

        user.is_active = not user.is_active
        user.save(update_fields=['is_active'])

        AuditLog.objects.create(
            user=request.user,
            action=f"User active status toggled: {user.full_name} -> {user.is_active}",
            details={'target_user_id': user.id, 'is_active': user.is_active}
        )

        return Response({"is_active": user.is_active, "message": "Foydalanuvchi holati yangilandi"})

class AdminComplaintViewSet(viewsets.ModelViewSet):
    serializer_class = ComplaintSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    queryset = Complaint.objects.all().select_related('reporter', 'reported_user', 'appointment')

class AdminSubscriptionPlanViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionPlanSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    queryset = SubscriptionPlan.objects.all()

class AdminAuditLogListView(generics.ListAPIView):
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    queryset = AuditLog.objects.all().select_related('user').order_by('-timestamp')
