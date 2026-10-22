import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../state/app_state.dart';
import '../widgets/alert_banner_widget.dart';
import '../widgets/lane_indicator_widget.dart';
import '../widgets/telemetry_card.dart';

class DriverHudScreen extends StatelessWidget {
  const DriverHudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final myVehicle = state.vehicles[state.myVehicleId];
    final hasAlert = state.hasActiveAlert;
    final alert = state.activeAlert;

    final isSameLaneAsAmb = state.ambulance.lane == state.myLane;
    final ambDistance = state.ambulance.latitude < (myVehicle?.latitude ?? 0)
        ? ((myVehicle!.latitude - state.ambulance.latitude) * 111320.0)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'EVAS',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.accent,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          // V2V status pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.safe,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'V2V',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              state.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: state.isSoundEnabled ? AppColors.textSecondary : AppColors.textMuted,
              size: 20,
            ),
            onPressed: () => context.read<AppState>().toggleSound(!state.isSoundEnabled),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Status Area (Alert or Safe)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: hasAlert && alert != null
                  ? AlertBannerWidget(
                      key: const ValueKey('alert'),
                      alert: alert,
                      onClearLaneLeft: state.myLane > 1
                          ? () => context.read<AppState>().setMyLane(state.myLane - 1)
                          : null,
                      onClearLaneRight: state.myLane < 3
                          ? () => context.read<AppState>().setMyLane(state.myLane + 1)
                          : null,
                    )
                  : _buildSafeCard(key: const ValueKey('safe'), state: state),
            ),
            const SizedBox(height: 24),

            // 2. Your Lane Selector
            LaneIndicatorWidget(
              currentLane: state.myLane,
              ambulanceLane: state.ambulance.lane,
              isAmbulanceApproaching: state.isEmergencyActive && isSameLaneAsAmb,
              onLaneSelected: (newLane) {
                context.read<AppState>().setMyLane(newLane);
              },
            ),
            const SizedBox(height: 16),

            // 3. Ambulance Approach Control
            _buildAmbulanceApproachCard(context, state),
            const SizedBox(height: 24),

            // 4. Telemetry
            Row(
              children: [
                Expanded(
                  child: TelemetryCard(
                    title: 'Speed',
                    value: myVehicle?.speedKmh.toStringAsFixed(0) ?? '40',
                    unit: 'km/h',
                    icon: Icons.speed,
                    accentColor: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TelemetryCard(
                    title: 'Amb. Distance',
                    value: ambDistance != null
                        ? ambDistance.toStringAsFixed(0)
                        : '—',
                    unit: ambDistance != null ? 'm' : '',
                    icon: Icons.straighten,
                    accentColor: hasAlert ? AppColors.emergency : AppColors.safe,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeCard({Key? key, required AppState state}) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        color: AppColors.safeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.safeBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent bar
          Container(
            width: 4,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.safe,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Path is Clear',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.isEmergencyActive
                        ? 'Ambulance in Lane ${state.ambulance.lane}. Your lane is safe.'
                        : 'No active emergency vehicles detected.',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
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

  Widget _buildAmbulanceApproachCard(BuildContext context, AppState state) {
    final ambLane = state.ambulance.lane;
    final isSirenOn = state.isEmergencyActive;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AMBULANCE LANE',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              // Siren toggle — minimal icon button
              GestureDetector(
                onTap: () => context.read<AppState>().toggleEmergencyMode(!isSirenOn),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSirenOn
                        ? AppColors.emergency.withOpacity(0.12)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSirenOn
                            ? Icons.notifications_active
                            : Icons.notifications_off_outlined,
                        size: 13,
                        color: isSirenOn ? AppColors.emergency : AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSirenOn ? 'ON' : 'OFF',
                        style: GoogleFonts.inter(
                          color: isSirenOn ? AppColors.emergency : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pill-style lane selector (matching lane indicator style)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [1, 2, 3].map((laneNum) {
                final isSelected = ambLane == laneNum;
                final laneSub = laneNum == 1 ? 'Left' : (laneNum == 2 ? 'Center' : 'Right');

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: laneNum > 1 ? 4 : 0),
                    child: GestureDetector(
                      onTap: () => context.read<AppState>().setAmbulanceLane(laneNum),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.emergency : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$laneNum',
                              style: GoogleFonts.inter(
                                color: isSelected ? Colors.white : AppColors.textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              laneSub,
                              style: GoogleFonts.inter(
                                color: isSelected ? Colors.white70 : AppColors.textMuted.withOpacity(0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
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
    );
  }
}
