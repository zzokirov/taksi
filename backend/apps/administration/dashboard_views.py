from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import user_passes_test
from django.contrib import messages
from django.db.models import Sum, Count
from apps.accounts.models import User, BarberProfile, CustomerProfile
from apps.appointments.models import Appointment
from apps.reviews.models import Review
from .models import Complaint, SubscriptionPlan, Subscription, AuditLog

def is_admin(user):
    return user.is_authenticated and (user.role == User.Role.ADMIN or user.is_staff or user.is_superuser)

@user_passes_test(is_admin, login_url='/admin/login/')
def dashboard_home(request):
    total_users = User.objects.count()
    total_barbers = BarberProfile.objects.count()
    pending_barbers = BarberProfile.objects.filter(verification_status='pending').count()
    total_appointments = Appointment.objects.count()
    completed_appointments = Appointment.objects.filter(status=Appointment.Status.COMPLETED).count()
    total_revenue = Appointment.objects.filter(status=Appointment.Status.COMPLETED).aggregate(s=Sum('service_price'))['s'] or 0
    pending_complaints = Complaint.objects.filter(status='pending').count()

    recent_appointments = Appointment.objects.select_related('customer', 'barber__user').order_by('-created_at')[:8]
    pending_barber_list = BarberProfile.objects.filter(verification_status='pending').select_related('user')[:5]

    context = {
        'total_users': total_users,
        'total_barbers': total_barbers,
        'pending_barbers': pending_barbers,
        'total_appointments': total_appointments,
        'completed_appointments': completed_appointments,
        'total_revenue': total_revenue,
        'pending_complaints': pending_complaints,
        'recent_appointments': recent_appointments,
        'pending_barber_list': pending_barber_list,
    }
    return render(request, 'admin_dashboard/index.html', context)

@user_passes_test(is_admin, login_url='/admin/login/')
def barbers_list(request):
    status_filter = request.GET.get('status', 'all')
    queryset = BarberProfile.objects.select_related('user', 'barbershop').order_by('-created_at')
    
    if status_filter != 'all':
        queryset = queryset.filter(verification_status=status_filter)

    return render(request, 'admin_dashboard/barbers.html', {'barbers': queryset, 'status_filter': status_filter})

@user_passes_test(is_admin, login_url='/admin/login/')
def verify_barber_action(request, pk):
    barber = get_object_or_404(BarberProfile, pk=pk)
    action = request.POST.get('action') # 'approve' or 'reject'
    notes = request.POST.get('notes', '')

    if action == 'approve':
        barber.verification_status = 'approved'
        barber.is_verified = True
        barber.verification_notes = notes
        barber.save()
        messages.success(request, f"{barber.user.full_name} tasdiqlandi!")
    elif action == 'reject':
        barber.verification_status = 'rejected'
        barber.is_verified = False
        barber.verification_notes = notes
        barber.save()
        messages.warning(request, f"{barber.user.full_name} rad etildi.")

    return redirect('dash-barbers')

@user_passes_test(is_admin, login_url='/admin/login/')
def appointments_list(request):
    status_filter = request.GET.get('status', 'all')
    queryset = Appointment.objects.select_related('customer', 'barber__user').order_by('-appointment_date', '-start_time')
    
    if status_filter != 'all':
        queryset = queryset.filter(status=status_filter)

    return render(request, 'admin_dashboard/appointments.html', {'appointments': queryset, 'status_filter': status_filter})

@user_passes_test(is_admin, login_url='/admin/login/')
def users_list(request):
    role_filter = request.GET.get('role', 'all')
    queryset = User.objects.all().order_by('-date_joined')
    
    if role_filter != 'all':
        queryset = queryset.filter(role=role_filter)

    return render(request, 'admin_dashboard/users.html', {'users': queryset, 'role_filter': role_filter})

@user_passes_test(is_admin, login_url='/admin/login/')
def toggle_user_active(request, pk):
    user = get_object_or_404(User, pk=pk)
    if user == request.user:
        messages.error(request, "O'zingizni to'xtata olmaysiz!")
    else:
        user.is_active = not user.is_active
        user.save()
        status_str = "faollashtirildi" if user.is_active else "bloklandi"
        messages.info(request, f"{user.full_name} {status_str}.")
    return redirect('dash-users')

@user_passes_test(is_admin, login_url='/admin/login/')
def complaints_list(request):
    complaints = Complaint.objects.select_related('reporter', 'reported_user', 'appointment').order_by('-created_at')
    return render(request, 'admin_dashboard/complaints.html', {'complaints': complaints})
