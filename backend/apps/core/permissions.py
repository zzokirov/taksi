from rest_framework import permissions

class IsAdminRole(permissions.BasePermission):
    """
    Allows access only to users with role='ADMIN' or is_staff/is_superuser.
    """
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            (request.user.role == 'ADMIN' or request.user.is_staff or request.user.is_superuser)
        )

class IsBarberUser(permissions.BasePermission):
    """
    Allows access only to authenticated users with role='BARBER'.
    """
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.role == 'BARBER'
        )

class IsApprovedBarberUser(permissions.BasePermission):
    """
    Allows access only to barbers whose profiles have been approved by an administrator.
    """
    def has_permission(self, request, view):
        if not (request.user and request.user.is_authenticated and request.user.role == 'BARBER'):
            return False
        profile = getattr(request.user, 'barber_profile', None)
        return bool(profile and profile.is_verified and profile.verification_status == 'approved')

class IsCustomerUser(permissions.BasePermission):
    """
    Allows access only to authenticated users with role='CUSTOMER'.
    """
    def has_permission(self, request, view):
        return bool(
            request.user and
            request.user.is_authenticated and
            request.user.role == 'CUSTOMER'
        )

class IsOwnerOrAdmin(permissions.BasePermission):
    """
    Object-level permission to allow only owners of an object or admins to edit/delete it.
    """
    def has_object_permission(self, request, view, obj):
        if request.user.is_staff or request.user.role == 'ADMIN':
            return True
        user_field = getattr(obj, 'user', None) or getattr(obj, 'customer', None)
        return user_field == request.user
