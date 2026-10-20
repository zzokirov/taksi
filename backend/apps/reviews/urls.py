from django.urls import path
from . import views

urlpatterns = [
    path('', views.ReviewCreateView.as_view(), name='create-review'),
    path('barber/<int:barber_id>/', views.BarberReviewsListView.as_view(), name='barber-reviews'),
]
