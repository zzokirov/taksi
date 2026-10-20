class ApiConstants {
  // Can be overridden with: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Standard Android Emulator host
  );

  // Authentication
  static const String login = '/api/auth/login/';
  static const String registerCustomer = '/api/auth/register/customer/';
  static const String registerBarber = '/api/auth/register/barber/';
  static const String refreshToken = '/api/auth/token/refresh/';
  static const String currentUser = '/api/auth/me/';
  static const String updateCustomerProfile = '/api/auth/profile/customer/';
  static const String updateBarberProfile = '/api/auth/profile/barber/';
  static const String changePassword = '/api/auth/change-password/';
  static const String updateFcmToken = '/api/auth/fcm-token/';

  // Barbers
  static const String barbers = '/api/barbers/';
  static String barberDetail(int id) => '/api/barbers/$id/';
  static const String barberOverview = '/api/barbers/dashboard/overview/';
  static const String barberWorkingHours = '/api/barbers/dashboard/working-hours/';
  static const String barberCustomers = '/api/barbers/dashboard/customers/';
  static const String barberRevenueStats = '/api/barbers/dashboard/revenue-stats/';
  static const String barberServices = '/api/barbers/dashboard/my-services/';
  static const String barberBreakTimes = '/api/barbers/dashboard/my-break-times/';
  static const String barberBlockedSlots = '/api/barbers/dashboard/my-blocked-slots/';

  // Appointments
  static const String availableSlots = '/api/appointments/available-slots/';
  static const String bookAppointment = '/api/appointments/book/';
  static const String customerAppointments = '/api/appointments/my-appointments/';
  static const String barberAppointments = '/api/appointments/barber-appointments/';
  static String appointmentDetail(int id) => '/api/appointments/$id/';
  static String appointmentStatus(int id) => '/api/appointments/$id/status/';
  static String appointmentCancel(int id) => '/api/appointments/$id/cancel/';
  static String appointmentReschedule(int id) => '/api/appointments/$id/reschedule/';

  // Favorites
  static const String favorites = '/api/appointments/favorites/';
  static const String favoriteToggle = '/api/appointments/favorites/toggle/';

  // Reviews
  static const String reviews = '/api/reviews/';
  static String barberReviews(int barberId) => '/api/reviews/barber/$barberId/';

  // Notifications
  static const String notifications = '/api/notifications/';
  static const String markAllNotificationsRead = '/api/notifications/mark-all-read/';
}
