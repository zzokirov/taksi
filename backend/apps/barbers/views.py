from datetime import date, datetime, timedelta
from django.db.models import Q, Sum, Count, Avg
from django.utils import timezone
from rest_framework import generics, viewsets, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Service, WorkingHours, BreakTime, BlockedTimeSlot, DayOfWeek
from .serializers import (
    ServiceSerializer,
    WorkingHoursSerializer,
    BreakTimeSerializer,
    BlockedTimeSlotSerializer,
    BarberListSerializer,
    BarberDetailSerializer
)
from apps.accounts.models import BarberProfile, User
from apps.appointments.models import Appointment
from apps.core.permissions import IsBarberUser

class BarberListView(generics.ListAPIView):
    """
    Search and filter barbers for customers.
    Filters: search (name, barbershop), min_price, max_price, rating, service
    Sorting: rating (desc), min_price (asc/desc)
    """
    serializer_class = BarberListSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = BarberProfile.objects.select_related('user', 'barbershop').prefetch_related('services')
        
        # Only show verified/approved barbers to customers unless staff
        if not (self.request.user and (self.request.user.is_staff or self.request.user.role == 'ADMIN')):
            queryset = queryset.filter(Q(is_verified=True) | Q(verification_status='approved'))

        search = self.request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(user__first_name__icontains=search) |
                Q(user__last_name__icontains=search) |
                Q(barbershop_name__icontains=search) |
                Q(barbershop__name__icontains=search) |
                Q(address__icontains=search) |
                Q(services__name__icontains=search)
            ).distinct()

        min_rating = self.request.query_params.get('min_rating')
        if min_rating:
            queryset = queryset.filter(rating_avg__gte=float(min_rating))

        service_name = self.request.query_params.get('service')
        if service_name:
            queryset = queryset.filter(services__name__icontains=service_name, services__is_active=True).distinct()

        # Sorting
        sort_by = self.request.query_params.get('sort_by', 'rating')
        if sort_by == 'rating':
            queryset = queryset.order_by('-rating_avg', '-rating_count')
        elif sort_by == 'experience':
            queryset = queryset.order_by('-experience_years')
        elif sort_by == 'newest':
            queryset = queryset.order_by('-created_at')

        return queryset

class BarberDetailView(generics.RetrieveAPIView):
    serializer_class = BarberDetailSerializer
    permission_classes = [permissions.AllowAny]
    queryset = BarberProfile.objects.select_related('user', 'barbershop').prefetch_related('services', 'working_hours', 'break_times')

# Barber-facing Service Management
class BarberServiceViewSet(viewsets.ModelViewSet):
    serializer_class = ServiceSerializer
    permission_classes = [permissions.IsAuthenticated, IsBarberUser]

    def get_queryset(self):
        barber = self.request.user.barber_profile
        return Service.objects.filter(barber=barber)

    def perform_create(self, serializer):
        serializer.save(barber=self.request.user.barber_profile)

# Barber-facing Working Hours
class BarberWorkingHoursView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsBarberUser]

    def get(self, request):
        barber = request.user.barber_profile
        # Initialize default 7 days if not present
        if not WorkingHours.objects.filter(barber=barber).exists():
            for day in range(7):
                WorkingHours.objects.create(
                    barber=barber,
                    day_of_week=day,
                    is_working_day=(day < 6), # Mon-Sat work, Sun off
                    start_time='09:00:00',
                    end_time='19:00:00'
                )
        hours = WorkingHours.objects.filter(barber=barber).order_by('day_of_week')
        return Response(WorkingHoursSerializer(hours, many=True).data)

    def post(self, request):
        barber = request.user.barber_profile
        data = request.data
        if isinstance(data, list):
            for item in data:
                day = item.get('day_of_week')
                if day is not None:
                    WorkingHours.objects.update_or_create(
                        barber=barber,
                        day_of_week=day,
                        defaults={
                            'is_working_day': item.get('is_working_day', True),
                            'start_time': item.get('start_time', '09:00:00'),
                            'end_time': item.get('end_time', '19:00:00'),
                        }
                    )
        hours = WorkingHours.objects.filter(barber=barber).order_by('day_of_week')
        return Response(WorkingHoursSerializer(hours, many=True).data)

# Barber-facing Break Times
class BarberBreakTimeViewSet(viewsets.ModelViewSet):
    serializer_class = BreakTimeSerializer
    permission_classes = [permissions.IsAuthenticated, IsBarberUser]

    def get_queryset(self):
        return BreakTime.objects.filter(barber=self.request.user.barber_profile)

    def perform_create(self, serializer):
        serializer.save(barber=self.request.user.barber_profile)

# Barber-facing Blocked Time Slots
class BarberBlockedSlotViewSet(viewsets.ModelViewSet):
    serializer_class = BlockedTimeSlotSerializer
    permission_classes = [permissions.IsAuthenticated, IsBarberUser]

    def get_queryset(self):
        return BlockedTimeSlot.objects.filter(barber=self.request.user.barber_profile)

    def perform_create(self, serializer):
        serializer.save(barber=self.request.user.barber_profile)

# Barber Dashboard: Overview Statistics
class BarberOverviewView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsBarberUser]

    def get(self, request):
        barber = request.user.barber_profile
        today = timezone.localdate()
        month_start = today.replace(day=1)

        today_appointments = Appointment.objects.filter(barber=barber, appointment_date=today)
        
        # Revenue is counted only on COMPLETED appointments
        today_revenue = today_appointments.filter(
            status=Appointment.Status.COMPLETED
        ).aggregate(total=Sum('service_price'))['total'] or 0

        monthly_revenue = Appointment.objects.filter(
            barber=barber,
            appointment_date__gte=month_start,
            appointment_date__lte=today,
            status=Appointment.Status.COMPLETED
        ).aggregate(total=Sum('service_price'))['total'] or 0

        pending_count = Appointment.objects.filter(barber=barber, status=Appointment.Status.PENDING).count()
        confirmed_count = today_appointments.filter(status=Appointment.Status.CONFIRMED).count()
        completed_count = today_appointments.filter(status=Appointment.Status.COMPLETED).count()
        total_today = today_appointments.count()

        return Response({
            'today': str(today),
            'today_bookings_count': total_today,
            'pending_requests_count': pending_count,
            'confirmed_appointments_count': confirmed_count,
            'completed_appointments_count': completed_count,
            'today_revenue': int(today_revenue),
            'monthly_revenue': int(monthly_revenue),
            'rating_avg': float(barber.rating_avg),
            'rating_count': barber.rating_count,
            'is_verified': barber.is_verified,
            'verification_status': barber.verification_status,
        })

# Barber Dashboard: Customer Database
class BarberCustomersView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsBarberUser]

    def get(self, request):
        barber = request.user.barber_profile
        # Find distinct customers who had appointments with this barber
        appointments = Appointment.objects.filter(barber=barber).select_related('customer')
        customer_ids = appointments.values_list('customer_id', flat=True).distinct()
        
        customers_data = []
        for c_id in customer_ids:
            user = User.objects.get(id=c_id)
            c_appointments = appointments.filter(customer=user).order_by('-appointment_date', '-start_time')
            total_visits = c_appointments.filter(status=Appointment.Status.COMPLETED).count()
            last_visit = c_appointments.filter(status=Appointment.Status.COMPLETED).first()
            last_visit_date = str(last_visit.appointment_date) if last_visit else None
            
            # Most booked service
            popular_service = c_appointments.values('service_name').annotate(cnt=Count('id')).order_by('-cnt').first()
            popular_service_name = popular_service['service_name'] if popular_service else 'Noma\'lum'

            # Customer note
            profile = getattr(user, 'customer_profile', None)
            notes = profile.notes if profile else ''

            customers_data.append({
                'id': user.id,
                'full_name': user.full_name,
                'phone_number': user.phone_number,
                'total_visits': total_visits,
                'last_visit_date': last_visit_date,
                'favorite_service': popular_service_name,
                'notes': notes,
            })

        return Response(customers_data)

# Barber Dashboard: Revenue Statistics
class BarberRevenueStatsView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsBarberUser]

    def get(self, request):
        barber = request.user.barber_profile
        today = timezone.localdate()

        # Last 7 days breakdown
        daily_stats = []
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            appts = Appointment.objects.filter(barber=barber, appointment_date=day, status=Appointment.Status.COMPLETED)
            rev = appts.aggregate(total=Sum('service_price'))['total'] or 0
            cnt = appts.count()
            daily_stats.append({
                'date': str(day),
                'day_name': day.strftime('%a'),
                'revenue': int(rev),
                'count': cnt
            })

        # Completed vs Cancelled
        all_appts = Appointment.objects.filter(barber=barber)
        total_completed = all_appts.filter(status=Appointment.Status.COMPLETED).count()
        total_cancelled = all_appts.filter(status=Appointment.Status.CANCELLED).count()
        total_revenue = all_appts.filter(status=Appointment.Status.COMPLETED).aggregate(total=Sum('service_price'))['total'] or 0

        # Popular services
        popular = all_appts.filter(status=Appointment.Status.COMPLETED).values('service_name').annotate(
            count=Count('id'),
            revenue=Sum('service_price')
        ).order_by('-count')[:5]

        return Response({
            'total_revenue': int(total_revenue),
            'total_completed': total_completed,
            'total_cancelled': total_cancelled,
            'daily_breakdown': daily_stats,
            'popular_services': list(popular),
        })
