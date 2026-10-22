import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/models/emergency_alert.dart';

class AlertBannerWidget extends StatelessWidget {
  final EmergencyAlert alert;
  final VoidCallback? onClearLaneLeft;
  final VoidCallback? onClearLaneRight;

  const AlertBannerWidget({
    super.key,
    required this.alert,
    this.onClearLaneLeft,
    this.onClearLaneRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.emergencyBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emergencyBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.emergency.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left accent bar
          Container(
            width: 4,
            decoration: const BoxDecoration(
              color: AppColors.emergency,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.emergency,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Emergency Vehicle Approaching',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Approaching behind in your lane',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Telemetry row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric('DISTANCE', '${alert.distanceMeters.toStringAsFixed(0)} m'),
                        Container(width: 1, height: 24, color: AppColors.borderSubtle),
                        _buildMetric('ETA', '${alert.etaSeconds} sec'),
                        Container(width: 1, height: 24, color: AppColors.borderSubtle),
                        _buildMetric('LANE', '${alert.ambulanceLane}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Advisory message
                  Text(
                    alert.humanMessage,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Evasion actions
                  Row(
                    children: [
                      if (onClearLaneLeft != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onClearLaneLeft,
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: Text(
                              'Evade Left',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderSubtle),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      if (onClearLaneLeft != null && onClearLaneRight != null)
                        const SizedBox(width: 10),
                      if (onClearLaneRight != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onClearLaneRight,
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: Text(
                              'Evade Right',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
