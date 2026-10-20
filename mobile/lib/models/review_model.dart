class ReviewModel {
  final int id;
  final int appointmentId;
  final int customerId;
  final String customerName;
  final String? customerAvatar;
  final int barberId;
  final int rating;
  final String comment;
  final String formattedDate;

  ReviewModel({
    required this.id,
    required this.appointmentId,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.barberId,
    required this.rating,
    required this.comment,
    required this.formattedDate,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? 0,
      appointmentId: json['appointment'] ?? 0,
      customerId: json['customer'] ?? 0,
      customerName: json['customer_name'] ?? 'Mijoz',
      customerAvatar: json['customer_avatar'],
      barberId: json['barber'] ?? 0,
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
      formattedDate: json['formatted_date'] ?? '',
    );
  }
}
