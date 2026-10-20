from datetime import datetime, timedelta
from django.db import transaction
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Appointment, Favorite
from .serializers import (
    AppointmentCreateSerializer,
    AppointmentListSerializer,
    AppointmentStatusUpdateSerializer,
    AppointmentRescheduleSerializer,
    FavoriteSerializer
)
from .availability import get_available_slots
from apps.accounts.models import BarberProfile, User
from apps.barbers.models import Service
from apps.core.permissions import IsCustomerUser, IsBarberUser
from apps.notifications.models import Notification

class AvailableSlotsView(APIView):
    """
    Public / Authenticated: Returns available time slots for a given barber, date and optional service.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        barber_id = request.query_params.get('barber_id')
        date_str = request.query_params.get('date')
        service_id = request.query_params.get('service_id')

        if not barber_id or not date_str:
            return Response(
                {"error": "barber_id va date (YYYY-MM-DD) parametrlari talab qilinadi"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            barber = BarberProfile.objects.get(id=barber_id)
        except BarberProfile.DoesNotExist:
            return Response({"error": "Sartarosh topilmadi"}, status=status.HTTP_404_NOT_FOUND)

        duration = 30
        if service_id:
            try:
                service = Service.objects.get(id=service_id, barber=barber)
                duration = service.duration_minutes
            except Service.DoesNotExist:
                pass

        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response({"error": "Sana formati noto'g'ri (YYYY-MM-DD)"}, status=status.HTTP_400_BAD_REQUEST)

        slots = get_available_slots(barber, target_date, service_duration_minutes=duration)
        return Response({
            'barber_id': barber.id,
            'date': str(target_date),
            'service_duration_minutes': duration,
            'available_slots': slots
        })

class AppointmentCreateView(generics.CreateAPIView):
    serializer_class = AppointmentCreateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        appointment = serializer.save()
        
        # Send Notification to Barber
        Notification.objects.create(
            user=appointment.barber.user,
            title="Yangi buyurtma!",
            body=f"{appointment.customer.full_name} {appointment.service_name} xizmati uchun {appointment.appointment_date} {appointment.start_time.strftime('%H:%M')} ga yozildi.",
            notification_type=Notification.NotificationType.BOOKING_CREATED,
            data={'appointment_id': appointment.id}
        )

class CustomerAppointmentsListView(generics.ListAPIView):
    serializer_class = AppointmentListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        queryset = Appointment.objects.filter(customer=user).select_related('barber__user', 'service')
        
        status_filter = self.request.query_params.get('status')
        today = timezone.localdate()
        now_time = timezone.localtime().time()

        if status_filter == 'upcoming':
            queryset = queryset.filter(
                status=Appointment.Status.CONFIRMED,
                appointment_date__gte=today
            )
        elif status_filter == 'pending':
            queryset = queryset.filter(status=Appointment.Status.PENDING)
        elif status_filter == 'completed':
            queryset = queryset.filter(status=Appointment.Status.COMPLETED)
        elif status_filter == 'cancelled':
            queryset = queryset.filter(status__in=[Appointment.Status.CANCELLED, Appointment.Status.NO_SHOW])

        return queryset.order_by('-appointment_date', '-start_time')

class BarberAppointmentsListView(generics.ListAPIView):
    serializer_class = AppointmentListSerializer
    permission_classes = [permissions.IsAuthenticated, IsBarberUser]

    def get_queryset(self):
        barber = self.request.user.barber_profile
        queryset = Appointment.objects.filter(barber=barber).select_related('customer', 'service')

        status_filter = self.request.query_params.get('status')
        today = timezone.localdate()

        if status_filter == 'today':
            queryset = queryset.filter(appointment_date=today)
        elif status_filter == 'pending':
            queryset = queryset.filter(status=Appointment.Status.PENDING)
        elif status_filter == 'confirmed':
            queryset = queryset.filter(status=Appointment.Status.CONFIRMED)
        elif status_filter == 'completed':
            queryset = queryset.filter(status=Appointment.Status.COMPLETED)
        elif status_filter == 'cancelled':
            queryset = queryset.filter(status__in=[Appointment.Status.CANCELLED, Appointment.Status.NO_SHOW])

        return queryset.order_by('-appointment_date', '-start_time')

class AppointmentDetailView(generics.RetrieveAPIView):
    serializer_class = AppointmentListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == User.Role.BARBER:
            return Appointment.objects.filter(barber=user.barber_profile)
        elif user.role == User.Role.ADMIN or user.is_staff:
            return Appointment.objects.all()
        return Appointment.objects.filter(customer=user)

class AppointmentStatusUpdateView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsBarberUser]

    def post(self, request, pk):
        barber = request.user.barber_profile
        try:
            appointment = Appointment.objects.get(id=pk, barber=barber)
        except Appointment.DoesNotExist:
            return Response({"error": "Buyurtma topilmadi"}, status=status.HTTP_404_NOT_FOUND)

        serializer = AppointmentStatusUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_status = serializer.validated_data['status']
        reason = serializer.validated_data.get('reason', '')

        appointment.status = new_status
        if new_status == Appointment.Status.CANCELLED:
            appointment.rejection_reason = reason
            appointment.cancelled_by = request.user
        appointment.save()

        # Send notification to Customer
        status_messages = {
            Appointment.Status.CONFIRMED: ("Buyurtma tasdiqlandi!", f"{barber.user.full_name} sizning qabulingizni tasdiqladi.", Notification.NotificationType.BOOKING_CONFIRMED),
            Appointment.Status.CANCELLED: ("Buyurtma rad etildi", f"{barber.user.full_name} buyurtmangizni rad etdi: {reason}", Notification.NotificationType.BOOKING_REJECTED),
            Appointment.Status.COMPLETED: ("Xizmat yakunlandi", "Xizmat uchun rahmat! Sartaroshga baxo va sharh qoldirishingiz mumkin.", Notification.NotificationType.SYSTEM),
            Appointment.Status.NO_SHOW: ("Kelmadi deb belgilandi", "Siz qabulga kelmadingiz deb belgilandi.", Notification.NotificationType.SYSTEM),
        }

        if new_status in status_messages:
            title, body, ntype = status_messages[new_status]
            Notification.objects.create(
                user=appointment.customer,
                title=title,
                body=body,
                notification_type=ntype,
                data={'appointment_id': appointment.id}
            )

        return Response(AppointmentListSerializer(appointment).data)

class AppointmentCancelView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        try:
            if user.role == User.Role.BARBER:
                appointment = Appointment.objects.get(id=pk, barber=user.barber_profile)
            else:
                appointment = Appointment.objects.get(id=pk, customer=user)
        except Appointment.DoesNotExist:
            return Response({"error": "Buyurtma topilmadi"}, status=status.HTTP_404_NOT_FOUND)

        reason = request.data.get('reason', 'Mijoz tomonidan bekor qilindi')
        appointment.status = Appointment.Status.CANCELLED
        appointment.cancellation_reason = reason
        appointment.cancelled_by = user
        appointment.save()

        # Notify the other party
        recipient = appointment.barber.user if user == appointment.customer else appointment.customer
        Notification.objects.create(
            user=recipient,
            title="Buyurtma bekor qilindi",
            body=f"{user.full_name} {appointment.appointment_date} dagi buyurtmani bekor qildi. Sabab: {reason}",
            notification_type=Notification.NotificationType.BOOKING_CANCELLED,
            data={'appointment_id': appointment.id}
        )

        return Response(AppointmentListSerializer(appointment).data)

class AppointmentRescheduleView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        user = request.user
        try:
            if user.role == User.Role.BARBER:
                appointment = Appointment.objects.get(id=pk, barber=user.barber_profile)
            else:
                appointment = Appointment.objects.get(id=pk, customer=user)
        except Appointment.DoesNotExist:
            return Response({"error": "Buyurtma topilmadi"}, status=status.HTTP_404_NOT_FOUND)

        serializer = AppointmentRescheduleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        new_date = serializer.validated_data['new_date']
        time_str = serializer.validated_data['new_time_str']

        try:
            start_t = datetime.strptime(time_str.strip(), '%H:%M').time()
        except ValueError:
            return Response({"error": "Vaqt formati xato (HH:MM)"}, status=status.HTTP_400_BAD_REQUEST)

        duration = appointment.service_duration_minutes
        end_t = (datetime.combine(new_date, start_t) + timedelta(minutes=duration)).time()

        with transaction.atomic():
            conflict = Appointment.objects.select_for_update().filter(
                barber=appointment.barber,
                appointment_date=new_date,
                status__in=[Appointment.Status.PENDING, Appointment.Status.CONFIRMED],
                start_time__lt=end_t,
                end_time__gt=start_t
            ).exclude(id=appointment.id).exists()

            if conflict:
                return Response({"error": "Tanlangan vaqt band!"}, status=status.HTTP_400_BAD_REQUEST)

            appointment.appointment_date = new_date
            appointment.start_time = start_t
            appointment.end_time = end_t
            appointment.status = Appointment.Status.PENDING # Needs re-confirmation
            appointment.save()

        # Notify
        recipient = appointment.barber.user if user == appointment.customer else appointment.customer
        Notification.objects.create(
            user=recipient,
            title="Qabul vaqti ko'chirildi",
            body=f"{user.full_name} qabul vaqtini {new_date} {time_str} ga ko'chirishni so'radi.",
            notification_type=Notification.NotificationType.BOOKING_RESCHEDULED,
            data={'appointment_id': appointment.id}
        )

        return Response(AppointmentListSerializer(appointment).data)

class FavoriteToggleView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        barber_id = request.data.get('barber_id')
        if not barber_id:
            return Response({"error": "barber_id talab qilinadi"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            barber = BarberProfile.objects.get(id=barber_id)
        except BarberProfile.DoesNotExist:
            return Response({"error": "Sartarosh topilmadi"}, status=status.HTTP_404_NOT_FOUND)

        favorite, created = Favorite.objects.get_or_create(customer=request.user, barber=barber)
        if not created:
            favorite.delete()
            return Response({"favorited": False, "message": "Sevimlilardan o'chirildi"})
        return Response({"favorited": True, "message": "Sevimlilarga qo'shildi"})

class FavoriteListView(generics.ListAPIView):
    serializer_class = FavoriteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Favorite.objects.filter(customer=self.request.user).select_related('barber__user')
