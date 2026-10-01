import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aura_state_provider.dart';
import '../theme/aura_theme.dart';
import '../widgets/aura_ui_components.dart';
import '../models/aura_models.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aura = context.watch<AuraStateProvider>();
    final isDemo = aura.mode == AppDataMode.demo;
    final isWaiting = aura.isRealTimeWaiting;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isWaiting) ...[
            const WaitingForVehicleBanner(),
            const SizedBox(height: 12),
          ],

          // 1. Diagnostics Summary Bar
          _buildHealthStatusHeader(aura),
          const SizedBox(height: 14),

          // 2. Active Faults Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE FAULTS & ROOT-CAUSE ANALYSIS',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8),
              ),
              StatusBadge(
                label: '${aura.faults.length} ACTIVE',
                color: aura.faults.isEmpty ? AuraColors.healthyGreen : AuraColors.caliperRed,
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (aura.faults.isEmpty)
            AuraCard(
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AuraColors.healthyGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NO ACTIVE FAULTS DETECTED', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          isWaiting
                              ? 'Waiting for physical vehicle connection to pull DTC codes.'
                              : 'All sensor nodes & ECUs operating within nominal thresholds.',
                          style: const TextStyle(fontSize: 11, color: AuraColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...aura.faults.map((fault) => _buildFaultCard(fault)),

          const SizedBox(height: 16),

          // 3. Fault Classification Categories
          const Text(
            'FAULT CATEGORY MONITOR',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          _buildCategoryGrid(aura),
          const SizedBox(height: 16),

          // 4. CAN Bus Communication Health & Frame Monitor
          const Text(
            'CAN 2.0B BUS COMMUNICATION HEALTH',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          _buildCanBusHealthCard(aura, isDemo),
        ],
      ),
    );
  }

  Widget _buildHealthStatusHeader(AuraStateProvider aura) {
    return AuraCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryCol('Sensors', '${aura.sensors.values.where((s) => s.status == SensorStatus.healthy).length}/${aura.sensors.length}', AuraColors.healthyGreen),
          _summaryCol('ECU Status', aura.vehicleEcu.isOnline ? 'NOMINAL' : 'OFFLINE', aura.vehicleEcu.isOnline ? AuraColors.metallicIceBlue : AuraColors.offlineGrey),
          _summaryCol('CAN Errors', '${aura.canErrorCount}', aura.canErrorCount == 0 ? AuraColors.healthyGreen : AuraColors.caliperRed),
          _summaryCol('Recovery', aura.recoveryMode.name.toUpperCase(), aura.recoveryMode == RecoveryMode.normal ? AuraColors.healthyGreen : AuraColors.caliperRed),
        ],
      ),
    );
  }

  Widget _summaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AuraColors.titaniumGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildFaultCard(FaultItem fault) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AuraCard(
        borderColor: AuraColors.caliperRed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AuraColors.caliperRed, size: 18),
                    const SizedBox(width: 8),
                    Text(fault.id, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AuraColors.caliperRed)),
                  ],
                ),
                StatusBadge(label: fault.severity.name.toUpperCase(), color: AuraColors.caliperRed),
              ],
            ),
            const SizedBox(height: 8),
            Text(fault.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text('Affected: ${fault.affectedSensor} (${fault.affectedEcu})', style: const TextStyle(fontSize: 11, color: AuraColors.titaniumGrey)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AuraColors.deepCrimson.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AuraColors.caliperRed.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Recovery: ${fault.recoveryStatus}',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            if (fault.rootCauseProbabilities.isNotEmpty) ...[
              const Divider(height: 16),
              const Text('Probabilistic Root Cause Breakdown:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AuraColors.titaniumGrey)),
              const SizedBox(height: 6),
              ...fault.rootCauseProbabilities.entries.map((e) {
                final pct = (e.value * 100).toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.key, style: const TextStyle(fontSize: 11, color: AuraColors.textSecondary))),
                      Text('$pct%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AuraColors.metallicIceBlue, fontFamily: 'monospace')),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(AuraStateProvider aura) {
    final categories = [
      {'name': 'Sensor Fault', 'icon': Icons.sensors_rounded, 'hasFault': aura.faults.any((f) => f.rootCauseCategory.contains('Sensor'))},
      {'name': 'ECU Fault', 'icon': Icons.memory_rounded, 'hasFault': aura.faults.any((f) => f.rootCauseCategory.contains('ECU'))},
      {'name': 'CAN Fault', 'icon': Icons.alt_route_rounded, 'hasFault': aura.faults.any((f) => f.rootCauseCategory.contains('CAN'))},
      {'name': 'Power Fault', 'icon': Icons.bolt_rounded, 'hasFault': aura.faults.any((f) => f.rootCauseCategory.contains('Power'))},
      {'name': 'Software Fault', 'icon': Icons.code_rounded, 'hasFault': aura.faults.any((f) => f.rootCauseCategory.contains('Software'))},
      {'name': 'Thermal Fault', 'icon': Icons.thermostat_rounded, 'hasFault': aura.faults.any((f) => f.rootCauseCategory.contains('Thermal'))},
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: categories.map((cat) {
        final hasFault = cat['hasFault'] as bool;
        final color = hasFault ? AuraColors.caliperRed : AuraColors.healthyGreen;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AuraColors.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: hasFault ? AuraColors.caliperRed : AuraColors.borderSubtle),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat['icon'] as IconData, size: 16, color: color),
              const SizedBox(height: 4),
              Text(
                cat['name'] as String,
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: hasFault ? AuraColors.caliperRed : Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                hasFault ? 'FAULT' : 'NOMINAL',
                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCanBusHealthCard(AuraStateProvider aura, bool isDemo) {
    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CAN Bus Load: ${aura.canBusLoad.toStringAsFixed(1)}% • ${aura.canMessageCount} msgs',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              StatusBadge(
                label: aura.canConnected ? '500 KBPS' : 'DISCONNECTED',
                color: aura.canConnected ? AuraColors.healthyGreen : AuraColors.caliperRed,
              ),
            ],
          ),
          const Divider(height: 16),
          const Text('Recent CAN Frames:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AuraColors.titaniumGrey)),
          const SizedBox(height: 6),
          if (aura.canFrames.isEmpty)
            const Text('No CAN frames captured.', style: TextStyle(fontSize: 11, color: AuraColors.titaniumGrey))
          else
            ...aura.canFrames.take(4).map((frame) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text(frame.id, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AuraColors.metallicIceBlue, fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        frame.dataHex,
                        style: const TextStyle(fontSize: 10, color: AuraColors.textSecondary, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(frame.sourceEcu, style: const TextStyle(fontSize: 9.5, color: AuraColors.titaniumGrey)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
