from rest_framework import generics, permissions
from .models import Review
from .serializers import ReviewSerializer, ReviewCreateSerializer

class ReviewCreateView(generics.CreateAPIView):
    serializer_class = ReviewCreateSerializer
    permission_classes = [permissions.IsAuthenticated]

class BarberReviewsListView(generics.ListAPIView):
    serializer_class = ReviewSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        barber_id = self.kwargs.get('barber_id')
        return Review.objects.filter(
            barber_id=barber_id,
            is_moderated=True
        ).select_related('customer').order_by('-created_at')
