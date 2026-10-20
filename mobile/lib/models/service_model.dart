class ServiceModel {
  final int id;
  final int? barber;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final bool isActive;
  final String? image;

  ServiceModel({
    required this.id,
    this.barber,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    this.isActive = true,
    this.image,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? 0,
      barber: json['barber'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] != null) ? (json['price'] as num).toDouble() : 0.0,
      durationMinutes: json['duration_minutes'] ?? 30,
      isActive: json['is_active'] ?? true,
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price.toInt(),
      'duration_minutes': durationMinutes,
      'is_active': isActive,
    };
  }
}
