from django.urls import path
from . import views

urlpatterns = [
    path('available-slots/', views.AvailableSlotsView.as_view(), name='available-slots'),
    path('book/', views.AppointmentCreateView.as_view(), name='book-appointment'),
    path('my-appointments/', views.CustomerAppointmentsListView.as_view(), name='customer-appointments'),
    path('barber-appointments/', views.BarberAppointmentsListView.as_view(), name='barber-appointments'),
    path('<int:pk>/', views.AppointmentDetailView.as_view(), name='appointment-detail'),
    path('<int:pk>/status/', views.AppointmentStatusUpdateView.as_view(), name='appointment-status-update'),
    path('<int:pk>/cancel/', views.AppointmentCancelView.as_view(), name='appointment-cancel'),
    path('<int:pk>/reschedule/', views.AppointmentRescheduleView.as_view(), name='appointment-reschedule'),

    # Favorites
    path('favorites/', views.FavoriteListView.as_view(), name='favorite-list'),
    path('favorites/toggle/', views.FavoriteToggleView.as_view(), name='favorite-toggle'),
]
