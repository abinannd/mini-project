import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';

class LaneIndicatorWidget extends StatelessWidget {
  final int currentLane;
  final int ambulanceLane;
  final bool isAmbulanceApproaching;
  final ValueChanged<int>? onLaneSelected;

  const LaneIndicatorWidget({
    super.key,
    required this.currentLane,
    required this.ambulanceLane,
    required this.isAmbulanceApproaching,
    this.onLaneSelected,
  });

  @override
  Widget build(BuildContext context) {
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
                'YOUR LANE',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAmbulanceApproaching
                      ? AppColors.emergency.withOpacity(0.12)
                      : AppColors.safe.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAmbulanceApproaching ? 'SAME LANE' : 'CLEAR',
                  style: GoogleFonts.inter(
                    color: isAmbulanceApproaching ? AppColors.emergency : AppColors.safe,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pill-style 3-segment lane selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildSegment(1, 'Left'),
                const SizedBox(width: 4),
                _buildSegment(2, 'Center'),
                const SizedBox(width: 4),
                _buildSegment(3, 'Right'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(int laneNumber, String subtitle) {
    final isSelected = currentLane == laneNumber;
    final isAlertLane = isAmbulanceApproaching && ambulanceLane == laneNumber && isSelected;

    Color bgColor;
    Color textColor;
    Color subColor;

    if (isAlertLane) {
      bgColor = AppColors.emergency;
      textColor = Colors.white;
      subColor = Colors.white70;
    } else if (isSelected) {
      bgColor = AppColors.accent;
      textColor = Colors.white;
      subColor = Colors.white70;
    } else {
      bgColor = Colors.transparent;
      textColor = AppColors.textMuted;
      subColor = AppColors.textMuted.withOpacity(0.6);
    }

    return Expanded(
      child: GestureDetector(
        onTap: onLaneSelected != null ? () => onLaneSelected!(laneNumber) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$laneNumber',
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: subColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
