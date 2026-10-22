import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/vehicle_node.dart';
import '../core/models/emergency_alert.dart';
import '../core/services/simulation_engine.dart';
import '../core/services/alert_sound_service.dart';
import '../core/services/websocket_service.dart';
import '../core/services/location_service.dart';

enum AppRole {
  driver,
  ambulanceOperator,
  vivaSimulation,
}

class AppState extends ChangeNotifier {
  final SimulationEngine _simEngine = SimulationEngine();
  final AlertFeedbackService _feedback = AlertFeedbackService();
  final WebSocketService _wsService = WebSocketService();
  final LocationService _locationService = LocationService();

  AppRole _currentRole = AppRole.driver;
  String _myVehicleId = 'V002';
  int _myLane = 2;
  bool _useBackend = false;
  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;

  EmergencyAlert? _activeAlert;
  StreamSubscription? _simSub;
  StreamSubscription? _wsAlertSub;

  AppState() {
    _init();
  }

  AppRole get currentRole => _currentRole;
  String get myVehicleId => _myVehicleId;
  int get myLane => _myLane;
  bool get useBackend => _useBackend;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isVibrationEnabled => _isVibrationEnabled;
  EmergencyAlert? get activeAlert => _activeAlert;
  bool get hasActiveAlert => _activeAlert != null;

  VehicleNode get ambulance => _simEngine.ambulance;
  Map<String, VehicleNode> get vehicles => _simEngine.vehicles;
  bool get isEmergencyActive => _simEngine.isEmergencyMode;
  bool get isPlayingSimulation => _simEngine.isPlaying;
  VehicleNode? get currentTargetVehicle => _simEngine.getTargetVehicle();
  bool get isWsConnected => _wsService.isConnected;
  String get backendUrl => _wsService.currentUrl;

  Future<void> _init() async {
    await _feedback.init();

    // Listen to Simulation Engine updates
    _simSub = _simEngine.onStateChange.listen((_) {
      _recalculateAlert();
      notifyListeners();
    });

    // Listen to WebSocket incoming alerts
    _wsAlertSub = _wsService.onEmergencyAlert.listen((alert) {
      if (_useBackend && alert.toId == _myVehicleId) {
        _activeAlert = alert;
        if (_isVibrationEnabled || _isSoundEnabled) {
          _feedback.startAlert(
            playSound: _isSoundEnabled,
            vibrate: _isVibrationEnabled,
          );
        }
        notifyListeners();
      }
    });

    // Initial evaluation
    _recalculateAlert();
  }

  void _recalculateAlert() {
    if (_useBackend) return;

    final alert = _simEngine.evaluateTargeting(_myVehicleId);
    _activeAlert = alert;

    if (!_isVibrationEnabled && !_isSoundEnabled) {
      _feedback.stopAlert();
      notifyListeners();
      return;
    }

    // ONLY alert & vibrate when emergency is active AND both vehicles are in the SAME lane
    if (_simEngine.isEmergencyMode && alert != null) {
      _feedback.startAlert(
        playSound: _isSoundEnabled,
        vibrate: _isVibrationEnabled,
      );
    } else {
      // In different lanes or siren off: stop all vibration and audio immediately
      _feedback.stopAlert();
    }
    notifyListeners();
  }

  // Role Switcher
  void setRole(AppRole role) {
    _currentRole = role;
    notifyListeners();
  }

  // Driver Lane Controls
  void setMyLane(int lane) {
    _feedback.triggerLaneSwitchFeedback();
    _myLane = lane;
    _simEngine.setVehicleLane(_myVehicleId, lane);
    _recalculateAlert();
    notifyListeners();
  }

  void setMyVehicleId(String id) {
    _feedback.triggerTapFeedback();
    _myVehicleId = id;
    if (_simEngine.vehicles.containsKey(id)) {
      _myLane = _simEngine.vehicles[id]!.lane;
    }
    _recalculateAlert();
    notifyListeners();
  }

  // Ambulance / Operator Controls
  void toggleEmergencyMode(bool active) {
    _feedback.triggerLaneSwitchFeedback();
    _simEngine.setEmergencyMode(active);
    _recalculateAlert();
    notifyListeners();
  }

  void setAmbulanceLane(int lane) {
    _feedback.triggerLaneSwitchFeedback();
    _simEngine.setAmbulanceLane(lane);
    _recalculateAlert();
    notifyListeners();
  }

  // Simulation Controls (for Viva Demo)
  void setVehicleLane(String vehicleId, int lane) {
    _simEngine.setVehicleLane(vehicleId, lane);
    if (vehicleId == _myVehicleId) {
      _myLane = lane;
    }
    _recalculateAlert();
    notifyListeners();
  }

  void toggleSimulationPlayback() {
    _simEngine.togglePlayback();
    notifyListeners();
  }

  void resetSimulation() {
    _simEngine.resetToDefaultScenario();
    _myLane = _simEngine.vehicles[_myVehicleId]?.lane ?? 2;
    _recalculateAlert();
    notifyListeners();
  }

  // Toggles
  void toggleSound(bool enabled) {
    _isSoundEnabled = enabled;
    _recalculateAlert();
  }

  void toggleVibration(bool enabled) {
    _isVibrationEnabled = enabled;
    _recalculateAlert();
  }

  void toggleUseBackend(bool use) {
    _useBackend = use;
    if (!_useBackend) {
      _recalculateAlert();
    }
    notifyListeners();
  }

  Future<void> connectBackend(String url) async {
    await _wsService.connect(url);
    _useBackend = true;
    notifyListeners();
  }

  void disconnectBackend() {
    _wsService.disconnect();
    _useBackend = false;
    _recalculateAlert();
    notifyListeners();
  }

  @override
  void dispose() {
    _simSub?.cancel();
    _wsAlertSub?.cancel();
    _simEngine.dispose();
    _feedback.dispose();
    _wsService.dispose();
    _locationService.dispose();
    super.dispose();
  }
}
