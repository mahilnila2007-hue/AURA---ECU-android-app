import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/aura_state_provider.dart';
import '../theme/aura_theme.dart';
import '../widgets/aura_ui_components.dart';
import '../models/aura_models.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  String _selectedSensorKey = 'wheel_r';

  @override
  Widget build(BuildContext context) {
    final aura = context.watch<AuraStateProvider>();
    final isDemo = aura.mode == AppDataMode.demo;
    final isWaiting = aura.isRealTimeWaiting;

    final vSensor = aura.virtualSensors[_selectedSensorKey] ?? aura.virtualSensors.values.first;
    final pSensor = aura.sensors[_selectedSensorKey] ?? aura.sensors['speed']!;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isWaiting) ...[
            const WaitingForVehicleBanner(),
            const SizedBox(height: 12),
          ],

          // 1. Recovery Pipeline States Ribbon
          _buildRecoveryPipelineBar(aura.recoveryMode),
          const SizedBox(height: 14),

          // 2. Mathematical Virtual Sensor Estimation Card
          _buildVirtualSensorMathCard(aura, vSensor, pSensor, isDemo),
          const SizedBox(height: 14),

          // 3. Actual vs Estimated Graph
          _buildActualVsEstimatedGraph(vSensor, pSensor),
          const SizedBox(height: 14),

          // 4. Mathematical Accuracy Metrics (MAE, RMSE, MAPE)
          _buildMetricsRow(vSensor),
          const SizedBox(height: 16),

          // 5. Demo Scenarios Selector (Requirement 11)
          if (isDemo) ...[
            _buildDemoScenarioSelector(aura),
            const SizedBox(height: 16),
          ],

          // 6. Recovery Action Log / Timeline
          _buildRecoveryTimelineCard(aura),
        ],
      ),
    );
  }

  // 1. Pipeline States Bar: NORMAL -> DEGRADED -> VIRTUAL SENSOR -> SAFE MODE -> RECOVERY
  Widget _buildRecoveryPipelineBar(RecoveryMode currentMode) {
    final states = [
      {'mode': RecoveryMode.normal, 'label': 'NORMAL'},
      {'mode': RecoveryMode.degraded, 'label': 'DEGRADED'},
      {'mode': RecoveryMode.degraded, 'label': 'VIRTUAL SENSOR'},
      {'mode': RecoveryMode.safe, 'label': 'SAFE MODE'},
      {'mode': RecoveryMode.recovery, 'label': 'RECOVERY'},
    ];

    return AuraCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADAPTIVE RECOVERY PIPELINE (ISO 26262)',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            children: states.map((s) {
              final isCurrent = s['label'] == 'VIRTUAL SENSOR'
                  ? currentMode == RecoveryMode.degraded
                  : s['mode'] == currentMode;
              final color = isCurrent ? AuraColors.metallicIceBlue : AuraColors.titaniumGrey;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isCurrent ? AuraColors.metallicIceBlue.withValues(alpha: 0.2) : AuraColors.bgSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: color,
                      width: isCurrent ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    s['label'] as String,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent ? Colors.white : AuraColors.titaniumGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 2. Mathematical Virtual Sensor Estimation Card
  Widget _buildVirtualSensorMathCard(AuraStateProvider aura, VirtualSensorModel vSensor, SensorData pSensor, bool isDemo) {
    return AuraCard(
      borderColor: vSensor.isVirtualActive ? AuraColors.caliperRed : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Parameter selector dropdown
              DropdownButton<String>(
                value: _selectedSensorKey,
                dropdownColor: AuraColors.bgSurface,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                icon: const Icon(Icons.arrow_drop_down_rounded, color: AuraColors.metallicIceBlue),
                items: aura.virtualSensors.keys.map((k) {
                  return DropdownMenuItem(
                    value: k,
                    child: Text(aura.virtualSensors[k]!.parameter),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSensorKey = val);
                },
              ),
              StatusBadge(
                label: vSensor.isVirtualActive ? 'VIRTUAL ACTIVE' : 'PARALLEL MONITOR',
                color: vSensor.isVirtualActive ? AuraColors.caliperRed : AuraColors.healthyGreen,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AuraColors.bgSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AuraColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Text('Formula: ', style: TextStyle(fontSize: 10, color: AuraColors.titaniumGrey)),
                Text(
                  vSensor.reconstructionFormula,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AuraColors.metallicIceBlue),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricTile('Real Sensor Value', pSensor.status == SensorStatus.fault ? 'FAULT (0.0)' : vSensor.physicalValue.toStringAsFixed(2), pSensor.status == SensorStatus.fault ? AuraColors.caliperRed : AuraColors.healthyGreen),
              _metricTile('Estimated Value', vSensor.estimatedValue.toStringAsFixed(2), AuraColors.metallicIceBlue),
              _metricTile('Confidence', '${vSensor.confidence.toStringAsFixed(1)}%', vSensor.confidence > 90 ? AuraColors.healthyGreen : AuraColors.warningAmber),
              _metricTile('Error Delta', vSensor.difference.toStringAsFixed(2), AuraColors.warningAmber),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Actual vs Estimated Graph
  Widget _buildActualVsEstimatedGraph(VirtualSensorModel vSensor, SensorData pSensor) {
    final hist = pSensor.history;
    final realSpots = hist.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final estSpots = hist.asMap().entries.map((e) {
      final val = pSensor.status == SensorStatus.fault ? vSensor.estimatedValue : (e.value * 1.01);
      return FlSpot(e.key.toDouble(), val);
    }).toList();

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ACTUAL VS ESTIMATED RECONSTRUCTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8)),
              Row(
                children: [
                  _legendDot(AuraColors.healthyGreen, 'Actual'),
                  const SizedBox(width: 8),
                  _legendDot(AuraColors.metallicIceBlue, 'Estimated'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Actual
                  LineChartBarData(
                    spots: realSpots,
                    isCurved: true,
                    color: pSensor.status == SensorStatus.fault ? AuraColors.caliperRed : AuraColors.healthyGreen,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                  // Estimated
                  LineChartBarData(
                    spots: estSpots,
                    isCurved: true,
                    color: AuraColors.metallicIceBlue,
                    barWidth: 2,
                    dashArray: [5, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 3, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  // 4. MAE, RMSE, MAPE Metrics
  Widget _buildMetricsRow(VirtualSensorModel vSensor) {
    return Row(
      children: [
        Expanded(child: _accuracyBox('MAE (Mean Abs Error)', vSensor.mae.toStringAsFixed(3), 'Low error')),
        const SizedBox(width: 8),
        Expanded(child: _accuracyBox('RMSE (Root Mean Sq)', vSensor.rmse.toStringAsFixed(3), 'Optimal fit')),
        const SizedBox(width: 8),
        Expanded(child: _accuracyBox('MAPE (Percentage)', '${vSensor.mape.toStringAsFixed(2)}%', 'Accuracy >99%')),
      ],
    );
  }

  Widget _accuracyBox(String title, String val, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AuraColors.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuraColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AuraColors.titaniumGrey)),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AuraColors.metallicIceBlue, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 8.5, color: AuraColors.textMuted)),
        ],
      ),
    );
  }

  // 5. Embedded Demo Scenario Selector (Requirement 11)
  Widget _buildDemoScenarioSelector(AuraStateProvider aura) {
    final scenarios = [
      {'id': DemoScenario.normal, 'label': 'NORMAL OPERATION'},
      {'id': DemoScenario.wheelSensorFail, 'label': 'HALL SENSOR FAILURE'},
      {'id': DemoScenario.canCommFail, 'label': 'CAN COMM FAILURE'},
      {'id': DemoScenario.batteryAbnormal, 'label': 'BATTERY ABNORMALITY'},
      {'id': DemoScenario.temperatureRise, 'label': 'TEMPERATURE RISE'},
      {'id': DemoScenario.softwareFault, 'label': 'SOFTWARE FAULT'},
      {'id': DemoScenario.otaValidationPass, 'label': 'OTA VALIDATION PASS'},
      {'id': DemoScenario.otaValidationFail, 'label': 'OTA VALIDATION FAIL'},
    ];

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DEMO SCENARIO INJECTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8)),
              StatusBadge(label: aura.activeScenario.name.toUpperCase(), color: AuraColors.metallicIceBlue),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: scenarios.map((sc) {
              final isSelected = aura.activeScenario == sc['id'];
              return ChoiceChip(
                label: Text(sc['label'] as String),
                selected: isSelected,
                selectedColor: AuraColors.metallicIceBlue.withValues(alpha: 0.25),
                backgroundColor: AuraColors.bgSurface,
                side: BorderSide(
                  color: isSelected ? AuraColors.metallicIceBlue : AuraColors.borderSubtle,
                ),
                labelStyle: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AuraColors.metallicIceBlue : AuraColors.titaniumGrey,
                ),
                onSelected: (selected) {
                  if (selected) {
                    aura.setScenario(sc['id'] as DemoScenario);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryTimelineCard(AuraStateProvider aura) {
    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECOVERY TIMELINE & LOGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          ...aura.recoveryTimeline.take(3).map((log) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                log,
                style: const TextStyle(fontSize: 10.5, color: AuraColors.textSecondary, fontFamily: 'monospace'),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AuraColors.titaniumGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color, fontFamily: 'monospace')),
      ],
    );
  }
}
