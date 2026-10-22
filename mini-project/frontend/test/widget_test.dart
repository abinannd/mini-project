import 'package:flutter_test/flutter_test.dart';
import 'package:evas_app/main.dart';
import 'package:evas_app/core/services/simulation_engine.dart';

void main() {
  test('Section 7 & 11 Targeting Engine Unit Test', () {
    final engine = SimulationEngine();
    
    // 1. Lane 2 Test (Default): Both in Lane 2 -> Alert active
    expect(engine.ambulance.lane, equals(2));
    expect(engine.vehicles['V002']!.lane, equals(2));
    final alertLane2 = engine.evaluateTargeting('V002');
    expect(alertLane2, isNotNull);
    expect(alertLane2!.toId, equals('V002'));
    expect(alertLane2.ambulanceLane, equals(2));

    // 2. Safe clearance: Move V002 to Lane 1 while ambulance is in Lane 2 -> NULL (No alert)
    engine.setVehicleLane('V002', 1);
    expect(engine.evaluateTargeting('V002'), isNull);

    // 3. Lane 1 Test: Move ambulance to Lane 1 -> Both now in Lane 1 -> Alert active!
    engine.setAmbulanceLane(1);
    expect(engine.ambulance.lane, equals(1));
    expect(engine.vehicles['V002']!.lane, equals(1));
    final alertLane1 = engine.evaluateTargeting('V002');
    expect(alertLane1, isNotNull);
    expect(alertLane1!.ambulanceLane, equals(1));

    // 4. Lane 3 Test: Move both to Lane 3 -> Alert active!
    engine.setVehicleLane('V002', 3);
    engine.setAmbulanceLane(3);
    expect(engine.ambulance.lane, equals(3));
    expect(engine.vehicles['V002']!.lane, equals(3));
    final alertLane3 = engine.evaluateTargeting('V002');
    expect(alertLane3, isNotNull);
    expect(alertLane3!.ambulanceLane, equals(3));

    // 5. Mismatched lanes: Ambulance in Lane 2, car in Lane 3 -> NULL (No alert)
    engine.setAmbulanceLane(2);
    expect(engine.evaluateTargeting('V002'), isNull);

    // 6. Siren off: Even in same lane -> NULL (No alert)
    engine.setAmbulanceLane(3);
    engine.setEmergencyMode(false);
    expect(engine.evaluateTargeting('V002'), isNull);
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LaneAwareEVASApp());
    expect(find.byType(LaneAwareEVASApp), findsOneWidget);
  });
}
