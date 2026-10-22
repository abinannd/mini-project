class VehicleNode {
  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double headingDeg;
  final int lane; // 1 = Left, 2 = Center, 3 = Right
  final bool isEmergencyVehicle;
  final bool isTargeted;
  final DateTime lastUpdated;

  const VehicleNode({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.headingDeg,
    required this.lane,
    this.isEmergencyVehicle = false,
    this.isTargeted = false,
    required this.lastUpdated,
  });

  VehicleNode copyWith({
    String? id,
    String? label,
    double? latitude,
    double? longitude,
    double? speedKmh,
    double? headingDeg,
    int? lane,
    bool? isEmergencyVehicle,
    bool? isTargeted,
    DateTime? lastUpdated,
  }) {
    return VehicleNode(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedKmh: speedKmh ?? this.speedKmh,
      headingDeg: headingDeg ?? this.headingDeg,
      lane: lane ?? this.lane,
      isEmergencyVehicle: isEmergencyVehicle ?? this.isEmergencyVehicle,
      isTargeted: isTargeted ?? this.isTargeted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speedKmh,
      'heading': headingDeg,
      'lane': lane,
      'is_emergency': isEmergencyVehicle,
      'is_targeted': isTargeted,
      'timestamp': lastUpdated.toIso8601String(),
    };
  }

  factory VehicleNode.fromJson(Map<String, dynamic> json) {
    return VehicleNode(
      id: json['id'] as String,
      label: json['label'] as String? ?? json['id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speedKmh: (json['speed'] as num?)?.toDouble() ?? 0.0,
      headingDeg: (json['heading'] as num?)?.toDouble() ?? 0.0,
      lane: json['lane'] as int? ?? 1,
      isEmergencyVehicle: json['is_emergency'] as bool? ?? false,
      isTargeted: json['is_targeted'] as bool? ?? false,
      lastUpdated: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
