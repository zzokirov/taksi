class UserModel {
  final int id;
  final String phoneNumber;
  final String fullName;
  final String? email;
  final String role; // CUSTOMER, BARBER, ADMIN
  final CustomerProfileModel? customerProfile;
  final BarberProfileModel? barberProfile;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.email,
    required this.role,
    this.customerProfile,
    this.barberProfile,
  });

  bool get isCustomer => role == 'CUSTOMER';
  bool get isBarber => role == 'BARBER';
  bool get isAdmin => role == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      phoneNumber: json['phone_number'] ?? '',
      fullName: json['full_name'] ?? json['first_name'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'CUSTOMER',
      customerProfile: json['customer_profile'] != null
          ? CustomerProfileModel.fromJson(json['customer_profile'])
          : null,
      barberProfile: json['barber_profile'] != null
          ? BarberProfileModel.fromJson(json['barber_profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'email': email,
      'role': role,
    };
  }
}

class CustomerProfileModel {
  final int id;
  final String? avatar;
  final bool notificationEnabled;
  final String? notes;

  CustomerProfileModel({
    required this.id,
    this.avatar,
    this.notificationEnabled = true,
    this.notes,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    return CustomerProfileModel(
      id: json['id'] ?? 0,
      avatar: json['avatar'],
      notificationEnabled: json['notification_enabled'] ?? true,
      notes: json['notes'],
    );
  }
}

class BarberProfileModel {
  final int id;
  final bool isVerified;
  final String verificationStatus;
  final String? barbershopName;
  final String? address;
  final String? bio;
  final int experienceYears;
  final double ratingAvg;
  final int ratingCount;
  final String? avatar;
  final int slotIntervalMinutes;
  final int advanceBookingDays;

  BarberProfileModel({
    required this.id,
    required this.isVerified,
    required this.verificationStatus,
    this.barbershopName,
    this.address,
    this.bio,
    this.experienceYears = 1,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.avatar,
    this.slotIntervalMinutes = 30,
    this.advanceBookingDays = 14,
  });

  factory BarberProfileModel.fromJson(Map<String, dynamic> json) {
    return BarberProfileModel(
      id: json['id'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      verificationStatus: json['verification_status'] ?? 'pending',
      barbershopName: json['barbershop_name'],
      address: json['address'],
      bio: json['bio'],
      experienceYears: json['experience_years'] ?? 1,
      ratingAvg: (json['rating_avg'] != null) ? (json['rating_avg'] as num).toDouble() : 0.0,
      ratingCount: json['rating_count'] ?? 0,
      avatar: json['avatar'],
      slotIntervalMinutes: json['slot_interval_minutes'] ?? 30,
      advanceBookingDays: json['advance_booking_days'] ?? 14,
    );
  }
}
