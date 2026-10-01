import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aura_state_provider.dart';
import '../theme/aura_theme.dart';
import '../widgets/aura_ui_components.dart';
import '../models/aura_models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aura = context.watch<AuraStateProvider>();
    final isDemo = aura.mode == AppDataMode.demo;
    final isWaiting = aura.isRealTimeWaiting;

    final speedSensor = aura.sensors['speed'];
    final battVoltSensor = aura.sensors['battery_volt'];
    final tempSensor = aura.sensors['temperature'];
    final tofSensor = aura.sensors['tof_dist'];
    final battCurrSensor = aura.sensors['battery_curr'];
    final powerSensor = aura.sensors['power_cons'];

    // Check if any virtual sensor is actively reconstructing
    final isVirtualActive = aura.virtualSensors.values.any((v) => v.isVirtualActive);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // If Real-Time mode & not connected, show prominent banner
          if (isWaiting) ...[
            const WaitingForVehicleBanner(),
            const SizedBox(height: 12),
          ],

          // 1. Vehicle & ECU Health Overview Card
          _buildHealthOverview(aura, isDemo),
          const SizedBox(height: 12),

          // 2. Compact Live Telemetry Grid (Speed, Battery, Temp, ToF, Current, Power)
          const Text(
            'LIVE TELEMETRY SNAPSHOT',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              if (speedSensor != null) SensorCardWidget(sensor: speedSensor, isDemo: isDemo),
              if (battVoltSensor != null) SensorCardWidget(sensor: battVoltSensor, isDemo: isDemo),
              if (tempSensor != null) SensorCardWidget(sensor: tempSensor, isDemo: isDemo),
              if (tofSensor != null) SensorCardWidget(sensor: tofSensor, isDemo: isDemo),
              if (battCurrSensor != null) SensorCardWidget(sensor: battCurrSensor, isDemo: isDemo),
              if (powerSensor != null) SensorCardWidget(sensor: powerSensor, isDemo: isDemo),
            ],
          ),
          const SizedBox(height: 14),

          // 3. ECU & Network Status Section
          const Text(
            'ECU & NETWORK INFRASTRUCTURE',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          _buildEcuStatusCard(aura),
          const SizedBox(height: 14),

          // 4. Virtual Sensor Status Quick Banner
          _buildVirtualSensorBanner(aura, isVirtualActive),
        ],
      ),
    );
  }

  Widget _buildHealthOverview(AuraStateProvider aura, bool isDemo) {
    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed_rounded, color: AuraColors.metallicIceBlue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    aura.activeVehicleName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              GlobalModeBadge(mode: aura.mode, isConnected: !aura.isRealTimeWaiting),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _healthGauge(
                  title: 'Vehicle Health',
                  score: aura.vehicleHealthScore,
                  color: aura.vehicleHealthScore > 90 ? AuraColors.healthyGreen : AuraColors.warningAmber,
                ),
              ),
              Container(width: 1, height: 38, color: AuraColors.borderSubtle),
              Expanded(
                child: _healthGauge(
                  title: 'ECU Core Health',
                  score: aura.ecuHealthScore,
                  color: aura.ecuHealthScore > 90 ? AuraColors.metallicIceBlue : AuraColors.warningAmber,
                ),
              ),
              Container(width: 1, height: 38, color: AuraColors.borderSubtle),
              Expanded(
                child: _healthGauge(
                  title: 'CAN Bus Health',
                  score: aura.canSuccessRate,
                  color: aura.canConnected ? AuraColors.healthyGreen : AuraColors.caliperRed,
                  unit: '%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthGauge({required String title, required double score, required Color color, String unit = '%'}) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AuraColors.titaniumGrey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, fontFamily: 'monospace'),
            ),
            Text(unit, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _buildEcuStatusCard(AuraStateProvider aura) {
    return AuraCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          _statusRow(
            label: 'Vehicle ECU (ECU-V-01)',
            status: aura.vehicleEcu.isOnline ? 'ONLINE' : 'OFFLINE',
            isPositive: aura.vehicleEcu.isOnline,
            detail: aura.vehicleEcu.isOnline ? 'Load: ${aura.vehicleEcu.cpuLoad.toStringAsFixed(1)}%' : 'Disconnected',
          ),
          const Divider(height: 16),
          _statusRow(
            label: 'Safety ECU (ECU-S-AURA)',
            status: aura.safetyEcu.isOnline ? 'ONLINE' : 'OFFLINE',
            isPositive: aura.safetyEcu.isOnline,
            detail: aura.safetyEcu.isOnline ? 'Firmware: ${aura.safetyEcu.firmwareVersion}' : 'Disconnected',
          ),
          const Divider(height: 16),
          _statusRow(
            label: 'CAN Bus 2.0B Bus',
            status: aura.canConnected ? 'CONNECTED' : 'DISCONNECTED',
            isPositive: aura.canConnected,
            detail: aura.canConnected ? '${aura.canBusLoad.toStringAsFixed(1)}% load • 500 kbps' : 'Bus Offline',
          ),
        ],
      ),
    );
  }

  Widget _statusRow({required String label, required String status, required bool isPositive, required String detail}) {
    final color = isPositive ? AuraColors.healthyGreen : AuraColors.caliperRed;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 2),
            Text(detail, style: const TextStyle(fontSize: 10, color: AuraColors.titaniumGrey)),
          ],
        ),
        StatusBadge(label: status, color: color),
      ],
    );
  }

  Widget _buildVirtualSensorBanner(AuraStateProvider aura, bool isVirtualActive) {
    final color = isVirtualActive ? AuraColors.caliperRed : AuraColors.metallicIceBlue;
    return AuraCard(
      borderColor: isVirtualActive ? AuraColors.caliperRed : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isVirtualActive ? Icons.healing_rounded : Icons.auto_graph_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Virtual Sensor Reconstruction',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    StatusBadge(
                      label: isVirtualActive ? 'ACTIVE INJECTION' : 'STANDBY PARALLEL',
                      color: isVirtualActive ? AuraColors.caliperRed : AuraColors.healthyGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isVirtualActive
                    ? 'Sensor hardware fault mitigated via kinematic equations.'
                    : 'All mathematical observer kernels running in parallel (96.4% confidence).',
                  style: const TextStyle(fontSize: 10.5, color: AuraColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
