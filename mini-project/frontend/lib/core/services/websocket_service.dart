import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/emergency_alert.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String _currentUrl = 'ws://192.168.1.100:8000/ws';

  final _alertController = StreamController<EmergencyAlert>.broadcast();
  final _fleetController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<bool>.broadcast();

  Stream<EmergencyAlert> get onEmergencyAlert => _alertController.stream;
  Stream<Map<String, dynamic>> get onFleetUpdate => _fleetController.stream;
  Stream<bool> get onConnectionStatus => _statusController.stream;

  bool get isConnected => _isConnected;
  String get currentUrl => _currentUrl;

  Future<void> connect(String url) async {
    _currentUrl = url;
    disconnect();

    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          _isConnected = true;
          _statusController.add(true);
          _handleMessage(message);
        },
        onError: (err) {
          _isConnected = false;
          _statusController.add(false);
        },
        onDone: () {
          _isConnected = false;
          _statusController.add(false);
        },
      );

      _isConnected = true;
      _statusController.add(true);
    } catch (e) {
      _isConnected = false;
      _statusController.add(false);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _statusController.add(false);
  }

  void _handleMessage(dynamic rawMessage) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawMessage as String);
      final type = data['type'] as String?;

      if (type == 'emergency_alert' || data.containsKey('to_id')) {
        final alert = EmergencyAlert.fromJson(data);
        _alertController.add(alert);
      } else if (type == 'fleet_update' || data.containsKey('vehicles')) {
        _fleetController.add(data);
      }
    } catch (_) {}
  }

  void sendLocationUpdate({
    required String vehicleId,
    required double lat,
    required double lng,
    required double speedKmh,
    required double heading,
    required int lane,
  }) {
    if (!_isConnected || _channel == null) return;

    try {
      final payload = jsonEncode({
        'type': 'location_update',
        'id': vehicleId,
        'latitude': lat,
        'longitude': lng,
        'speed': speedKmh,
        'heading': heading,
        'lane': lane,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _channel!.sink.add(payload);
    } catch (_) {}
  }

  void dispose() {
    disconnect();
    _alertController.close();
    _fleetController.close();
    _statusController.close();
  }
}
