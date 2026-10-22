import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../state/app_state.dart';

class OperatorMapScreen extends StatefulWidget {
  const OperatorMapScreen({super.key});

  @override
  State<OperatorMapScreen> createState() => _OperatorMapScreenState();
}

class _OperatorMapScreenState extends State<OperatorMapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final amb = state.ambulance;
    final vehicles = state.vehicles;
    final targetVehicle = state.currentTargetVehicle;

    final ambLatLng = LatLng(amb.latitude, amb.longitude);

    final routePoints = [
      LatLng(amb.latitude - 0.002, amb.longitude),
      LatLng(amb.latitude, amb.longitude),
      LatLng(amb.latitude + 0.006, amb.longitude),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'Live Map',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Center on Ambulance',
            onPressed: () => _mapController.move(ambLatLng, 16.0),
          ),
          IconButton(
            icon: Icon(
              state.isPlayingSimulation ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: state.isPlayingSimulation ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
            tooltip: state.isPlayingSimulation ? 'Pause' : 'Play',
            onPressed: () => context.read<AppState>().toggleSimulationPlayback(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: ambLatLng,
              initialZoom: 16.0,
            ),
            children: [
              // Dark map tiles (CartoDB Dark Matter)
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.evas.laneaware.evas_app',
              ),

              // Route corridor
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 3,
                    color: state.isEmergencyActive
                        ? AppColors.emergency.withOpacity(0.5)
                        : AppColors.accent.withOpacity(0.3),
                  ),
                ],
              ),

              // Markers
              MarkerLayer(
                markers: [
                  Marker(
                    point: ambLatLng,
                    width: 40,
                    height: 40,
                    child: _buildAmbulanceMarker(state.isEmergencyActive),
                  ),
                  for (final v in vehicles.values)
                    Marker(
                      point: LatLng(v.latitude, v.longitude),
                      width: 36,
                      height: 36,
                      child: _buildVehicleMarker(
                        targetVehicle?.id == v.id,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top status pill
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: state.isEmergencyActive ? AppColors.emergency : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      targetVehicle != null
                          ? 'Targeting ${targetVehicle.id} • Lane ${targetVehicle.lane}'
                          : (state.isEmergencyActive
                              ? 'Emergency active • Path clear'
                              : 'Standby • Lane ${amb.lane}'),
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${amb.speedKmh.toStringAsFixed(0)} km/h',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom control card
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ambulance lane selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AMBULANCE LANE',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [1, 2, 3].map((lane) {
                            final isSelected = amb.lane == lane;
                            final laneSub = lane == 1 ? 'Left' : (lane == 2 ? 'Center' : 'Right');
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(left: lane > 1 ? 4 : 0),
                                child: GestureDetector(
                                  onTap: () => context.read<AppState>().setAmbulanceLane(lane),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.emergency : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$lane',
                                          style: GoogleFonts.inter(
                                            color: isSelected ? Colors.white : AppColors.textMuted,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          laneSub,
                                          style: GoogleFonts.inter(
                                            color: isSelected ? Colors.white70 : AppColors.textMuted.withOpacity(0.6),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Emergency toggle
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AppState>().toggleEmergencyMode(!state.isEmergencyActive);
                      },
                      icon: Icon(
                        state.isEmergencyActive
                            ? Icons.notifications_off_rounded
                            : Icons.notifications_active_rounded,
                        size: 18,
                      ),
                      label: Text(
                        state.isEmergencyActive ? 'Stop Siren' : 'Broadcast Siren',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.isEmergencyActive
                            ? AppColors.surfaceElevated
                            : AppColors.emergency,
                        foregroundColor: state.isEmergencyActive
                            ? AppColors.textSecondary
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbulanceMarker(bool isEmergency) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emergency,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: isEmergency
            ? [
                BoxShadow(
                  color: AppColors.emergency.withOpacity(0.4),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: const Center(
        child: Icon(Icons.local_hospital, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildVehicleMarker(bool isTargeted) {
    return Container(
      decoration: BoxDecoration(
        color: isTargeted ? AppColors.emergency : AppColors.surfaceElevated,
        shape: BoxShape.circle,
        border: Border.all(
          color: isTargeted ? Colors.white : AppColors.borderSubtle,
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.directions_car,
          color: isTargeted ? Colors.white : AppColors.textMuted,
          size: 14,
        ),
      ),
    );
  }
}
