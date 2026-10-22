class EmergencyAlert {
  final String toId;
  final String ambulanceId;
  final double ambulanceLat;
  final double ambulanceLon;
  final double distanceMeters;
  final int etaSeconds;
  final bool emergencyState;
  final String messageCode;
  final String humanMessage;
  final int ambulanceLane;
  final DateTime timestamp;

  const EmergencyAlert({
    required this.toId,
    this.ambulanceId = 'AMB01',
    required this.ambulanceLat,
    required this.ambulanceLon,
    required this.distanceMeters,
    required this.etaSeconds,
    required this.emergencyState,
    this.messageCode = 'EMERGENCY_ALERT_CLEAR_LANE',
    this.humanMessage = 'Emergency vehicle approaching. Please safely clear the path when safe and legal.',
    this.ambulanceLane = 2,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'to_id': toId,
      'ambulance_id': ambulanceId,
      'ambulance_lat': ambulanceLat,
      'ambulance_lon': ambulanceLon,
      'distance': distanceMeters,
      'eta': etaSeconds,
      'emergency_state': emergencyState,
      'message_code': messageCode,
      'human_message': humanMessage,
      'ambulance_lane': ambulanceLane,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      toId: json['to_id'] as String,
      ambulanceId: json['ambulance_id'] as String? ?? 'AMB01',
      ambulanceLat: (json['ambulance_lat'] as num).toDouble(),
      ambulanceLon: (json['ambulance_lon'] as num).toDouble(),
      distanceMeters: (json['distance'] as num).toDouble(),
      etaSeconds: (json['eta'] as num).toInt(),
      emergencyState: json['emergency_state'] as bool? ?? true,
      messageCode: json['message_code'] as String? ?? 'EMERGENCY_ALERT',
      humanMessage: json['human_message'] as String? ??
          'Emergency vehicle approaching. Please safely clear the path when safe and legal.',
      ambulanceLane: json['ambulance_lane'] as int? ?? 2,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
