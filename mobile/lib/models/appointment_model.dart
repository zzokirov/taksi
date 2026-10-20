class AppointmentModel {
  final int id;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final int barberId;
  final String barberName;
  final String barberPhone;
  final String? barberAvatar;
  final String? barbershopName;
  final int? serviceId;
  final String serviceName;
  final double servicePrice;
  final int serviceDurationMinutes;
  final String appointmentDate;
  final String startTime;
  final String endTime;
  final String formattedDate;
  final String formattedTime;
  final String status; // pending, confirmed, completed, cancelled, no_show
  final String? notes;
  final String? rejectionReason;
  final String? cancellationReason;
  final bool canCancel;
  final bool canReview;
  final bool hasReview;

  AppointmentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.barberId,
    required this.barberName,
    required this.barberPhone,
    this.barberAvatar,
    this.barbershopName,
    this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDurationMinutes,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    required this.formattedDate,
    required this.formattedTime,
    required this.status,
    this.notes,
    this.rejectionReason,
    this.cancellationReason,
    this.canCancel = false,
    this.canReview = false,
    this.hasReview = false,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isNoShow => status == 'no_show';

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? 0,
      customerId: json['customer'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      barberId: json['barber'] ?? 0,
      barberName: json['barber_name'] ?? '',
      barberPhone: json['barber_phone'] ?? '',
      barberAvatar: json['barber_avatar'],
      barbershopName: json['barbershop_name'],
      serviceId: json['service'],
      serviceName: json['service_name'] ?? '',
      servicePrice: (json['service_price'] != null) ? (json['service_price'] as num).toDouble() : 0.0,
      serviceDurationMinutes: json['service_duration_minutes'] ?? 30,
      appointmentDate: json['appointment_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      formattedDate: json['formatted_date'] ?? json['appointment_date'] ?? '',
      formattedTime: json['formatted_time'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      rejectionReason: json['rejection_reason'],
      cancellationReason: json['cancellation_reason'],
      canCancel: json['can_cancel'] ?? false,
      canReview: json['can_review'] ?? false,
      hasReview: json['has_review'] ?? false,
    );
  }
}
