import os
import json
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

def send_fcm_notification(fcm_token, title, body, data=None):
    """
    Sends push notification via Firebase Cloud Messaging.
    Gracefully handles missing credentials and logs debug messages.
    """
    if not fcm_token:
        return False

    fcm_server_key = os.getenv('FCM_SERVER_KEY')
    if not fcm_server_key:
        logger.info(f"[FCM STUB] No FCM_SERVER_KEY configured. Push simulated for token {fcm_token[:10]}... Title: {title}")
        return True

    try:
        import requests
        headers = {
            'Authorization': f'key={fcm_server_key}',
            'Content-Type': 'application/json'
        }
        payload = {
            'to': fcm_token,
            'notification': {
                'title': title,
                'body': body,
                'sound': 'default',
            },
            'data': data or {}
        }
        res = requests.post('https://fcm.googleapis.com/fcm/send', headers=headers, json=payload, timeout=5)
        return res.status_code == 200
    except Exception as e:
        logger.error(f"[FCM ERROR] Failed to send push notification: {e}")
        return False
