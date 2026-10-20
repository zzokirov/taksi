from rest_framework import serializers
from .models import Notification

class NotificationSerializer(serializers.ModelSerializer):
    formatted_time = serializers.SerializerMethodField()

    class Meta:
        model = Notification
        fields = [
            'id', 'title', 'body', 'notification_type',
            'is_read', 'data', 'formatted_time', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']

    def get_formatted_time(self, obj):
        return obj.created_at.strftime('%d.%m.%Y %H:%M')
