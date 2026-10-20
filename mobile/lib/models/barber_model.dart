import 'service_model.dart';

class BarberModel {
  final int id;
  final int userId;
  final String fullName;
  final String phoneNumber;
  final String barbershopName;
  final String? address;
  final String? bio;
  final String? avatar;
  final int experienceYears;
  final bool isVerified;
  final String verificationStatus;
  final double ratingAvg;
  final int ratingCount;
  final int slotIntervalMinutes;
  final int advanceBookingDays;
  final int servicesCount;
  final int minPrice;
  final bool isFavorite;
  final List<ServiceModel> services;

  BarberModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.barbershopName,
    this.address,
    this.bio,
    this.avatar,
    this.experienceYears = 1,
    this.isVerified = false,
    this.verificationStatus = 'pending',
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.slotIntervalMinutes = 30,
    this.advanceBookingDays = 14,
    this.servicesCount = 0,
    this.minPrice = 0,
    this.isFavorite = false,
    this.services = const [],
  });

  factory BarberModel.fromJson(Map<String, dynamic> json) {
    var rawServices = json['services'] as List?;
    List<ServiceModel> parsedServices = [];
    if (rawServices != null) {
      parsedServices = rawServices.map((e) => ServiceModel.fromJson(e)).toList();
    }

    return BarberModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      barbershopName: json['barbershop_name_display'] ?? json['barbershop_name'] ?? 'Mustaqil',
      address: json['address'],
      bio: json['bio'],
      avatar: json['avatar'],
      experienceYears: json['experience_years'] ?? 1,
      isVerified: json['is_verified'] ?? false,
      verificationStatus: json['verification_status'] ?? 'pending',
      ratingAvg: (json['rating_avg'] != null) ? (json['rating_avg'] as num).toDouble() : 0.0,
      ratingCount: json['rating_count'] ?? 0,
      slotIntervalMinutes: json['slot_interval_minutes'] ?? 30,
      advanceBookingDays: json['advance_booking_days'] ?? 14,
      servicesCount: json['services_count'] ?? parsedServices.length,
      minPrice: json['min_price'] ?? 0,
      isFavorite: json['is_favorite'] ?? false,
      services: parsedServices,
    );
  }

  BarberModel copyWith({bool? isFavorite}) {
    return BarberModel(
      id: id,
      userId: userId,
      fullName: fullName,
      phoneNumber: phoneNumber,
      barbershopName: barbershopName,
      address: address,
      bio: bio,
      avatar: avatar,
      experienceYears: experienceYears,
      isVerified: isVerified,
      verificationStatus: verificationStatus,
      ratingAvg: ratingAvg,
      ratingCount: ratingCount,
      slotIntervalMinutes: slotIntervalMinutes,
      advanceBookingDays: advanceBookingDays,
      servicesCount: servicesCount,
      minPrice: minPrice,
      isFavorite: isFavorite ?? this.isFavorite,
      services: services,
    );
  }
}
