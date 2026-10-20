from django.contrib import admin
from .models import Review

@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ('id', 'customer', 'barber', 'rating', 'is_moderated', 'created_at')
    list_filter = ('rating', 'is_moderated')
    search_fields = ('customer__first_name', 'barber__user__first_name', 'comment')
