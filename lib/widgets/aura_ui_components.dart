import 'package:flutter/material.dart';
import '../theme/aura_theme.dart';
import '../models/aura_models.dart';

class AuraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const AuraCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AuraColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? AuraColors.borderSubtle,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(14.0),
            child: child,
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class GlobalModeToggle extends StatelessWidget {
  final AppDataMode currentMode;
  final ValueChanged<AppDataMode> onModeChanged;

  const GlobalModeToggle({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDemo = currentMode == AppDataMode.demo;

    return Container(
      height: 34,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: AuraColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuraColors.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DEMO MODE BUTTON
          InkWell(
            onTap: () {
              if (!isDemo) onModeChanged(AppDataMode.demo);
            },
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDemo ? AuraColors.metallicIceBlue.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isDemo ? Border.all(color: AuraColors.metallicIceBlue, width: 1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sensors_rounded,
                    size: 13,
                    color: isDemo ? AuraColors.metallicIceBlue : AuraColors.titaniumGrey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'DEMO MODE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isDemo ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isDemo ? AuraColors.metallicIceBlue : AuraColors.titaniumGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // REAL-TIME MODE BUTTON
          InkWell(
            onTap: () {
              if (isDemo) {
                // Show brief confirmation or switch directly
                _confirmOrSwitch(context);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: !isDemo ? AuraColors.healthyGreen.withValues(alpha: 0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: !isDemo ? Border.all(color: AuraColors.healthyGreen, width: 1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 13,
                    color: !isDemo ? AuraColors.healthyGreen : AuraColors.titaniumGrey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'REAL-TIME',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: !isDemo ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.5,
                      color: !isDemo ? AuraColors.healthyGreen : AuraColors.titaniumGrey,
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

  void _confirmOrSwitch(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.bgSurface,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AuraColors.warningAmber, size: 22),
            SizedBox(width: 8),
            Text('Switch to Real-Time Mode?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
        content: const Text(
          'Simulated demo telemetry will be stopped immediately. If no physical vehicle hardware is connected, telemetry will display 0 values and show WAITING FOR VEHICLE.',
          style: TextStyle(fontSize: 13, color: AuraColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL', style: TextStyle(color: AuraColors.titaniumGrey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AuraColors.healthyGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('SWITCH TO REAL-TIME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            onPressed: () {
              Navigator.pop(ctx);
              onModeChanged(AppDataMode.realTime);
            },
          ),
        ],
      ),
    );
  }
}

class GlobalModeBadge extends StatelessWidget {
  final AppDataMode mode;
  final bool isConnected;

  const GlobalModeBadge({
    super.key,
    required this.mode,
    this.isConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == AppDataMode.demo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: AuraColors.metallicIceBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AuraColors.metallicIceBlue.withValues(alpha: 0.5), width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 3, backgroundColor: AuraColors.metallicIceBlue),
            SizedBox(width: 5),
            Text(
              'DEMO MODE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AuraColors.metallicIceBlue,
              ),
            ),
          ],
        ),
      );
    } else {
      final color = isConnected ? AuraColors.healthyGreen : AuraColors.warningAmber;
      final text = isConnected ? 'REAL-TIME (LIVE)' : 'REAL-TIME (WAITING)';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 3, backgroundColor: color),
            const SizedBox(width: 5),
            Text(
              text,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ],
        ),
      );
    }
  }
}

class WaitingForVehicleBanner extends StatelessWidget {
  const WaitingForVehicleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AuraColors.warningAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AuraColors.warningAmber.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_tethering_off_rounded, color: AuraColors.warningAmber, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REAL-TIME MODE • WAITING FOR VEHICLE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AuraColors.warningAmber),
                ),
                SizedBox(height: 2),
                Text(
                  'No physical ECU hardware stream detected. Telemetry held at zero values.',
                  style: TextStyle(fontSize: 10.5, color: AuraColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SensorCardWidget extends StatelessWidget {
  final SensorData sensor;
  final bool isDemo;
  final VoidCallback? onTap;

  const SensorCardWidget({
    super.key,
    required this.sensor,
    this.isDemo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (sensor.status) {
      case SensorStatus.healthy:
        statusColor = AuraColors.healthyGreen;
        statusText = 'HEALTHY';
        break;
      case SensorStatus.warning:
        statusColor = AuraColors.warningAmber;
        statusText = 'WARN';
        break;
      case SensorStatus.fault:
        statusColor = AuraColors.caliperRed;
        statusText = 'FAULT';
        break;
      case SensorStatus.offline:
        statusColor = AuraColors.offlineGrey;
        statusText = 'OFFLINE';
        break;
      case SensorStatus.virtualActive:
        statusColor = AuraColors.metallicIceBlue;
        statusText = 'VIRTUAL';
        break;
    }

    return AuraCard(
      onTap: onTap,
      borderColor: sensor.status == SensorStatus.fault ? AuraColors.caliperRed : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sensor.name,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AuraColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(label: statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                sensor.value.toStringAsFixed(
                  sensor.unit == 'V' || sensor.unit == 'A' || sensor.unit == 'rad/s' ? 2 : 1,
                ),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AuraColors.textPrimary,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                sensor.unit,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AuraColors.titaniumGrey,
                ),
              ),
              const Spacer(),
              if (isDemo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AuraColors.metallicIceBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SIMULATED',
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AuraColors.metallicIceBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MiniTrendChart(data: sensor.history, color: statusColor),
              Text(
                "${sensor.health.toStringAsFixed(0)}% hlth",
                style: const TextStyle(fontSize: 10, color: AuraColors.textMuted),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class MiniTrendChart extends StatelessWidget {
  final List<double> data;
  final Color color;

  const MiniTrendChart({
    super.key,
    required this.data,
    this.color = AuraColors.metallicIceBlue,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox(height: 22, width: 60);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    return SizedBox(
      height: 22,
      width: 65,
      child: CustomPaint(
        painter: _MiniSparklinePainter(data, minVal, range, color),
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final List<double> data;
  final double minVal;
  final double range;
  final Color color;

  _MiniSparklinePainter(this.data, this.minVal, this.range, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final dx = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final normY = (data[i] - minVal) / range;
      final y = size.height - (normY * (size.height - 4)) - 2;
      final x = i * dx;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) => true;
}
