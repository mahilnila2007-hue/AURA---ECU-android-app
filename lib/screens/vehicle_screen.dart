import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/aura_state_provider.dart';
import '../theme/aura_theme.dart';
import '../widgets/aura_ui_components.dart';
import '../models/aura_models.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aura = context.watch<AuraStateProvider>();
    final isDemo = aura.mode == AppDataMode.demo;
    final isWaiting = aura.isRealTimeWaiting;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AuraColors.bgSurface,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AuraColors.metallicIceBlue,
            labelColor: AuraColors.metallicIceBlue,
            unselectedLabelColor: AuraColors.titaniumGrey,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'PROPULSION & IMU'),
              Tab(text: 'POWER & BMS'),
              Tab(text: 'PROXIMITY & THERMAL'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPropulsionTab(aura, isDemo, isWaiting),
          _buildPowerTab(aura, isDemo, isWaiting),
          _buildThermalProximityTab(aura, isDemo, isWaiting),
        ],
      ),
    );
  }

  // 1. Propulsion & IMU Dynamics Tab
  Widget _buildPropulsionTab(AuraStateProvider aura, bool isDemo, bool isWaiting) {
    final speed = aura.sensors['speed']!;
    final wheelL = aura.sensors['wheel_l']!;
    final wheelR = aura.sensors['wheel_r']!;
    final yaw = aura.sensors['yaw_rate']!;
    final accX = aura.sensors['acc_x']!;
    final accY = aura.sensors['acc_y']!;
    final accZ = aura.sensors['acc_z']!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isWaiting) ...[
          const WaitingForVehicleBanner(),
          const SizedBox(height: 12),
        ],

        // Main Speed & Wheel Differential Card
        AuraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PROPULSION TELEMETRY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8)),
                  if (isDemo)
                    const Text('SIMULATED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AuraColors.metallicIceBlue)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _paramTile('Vehicle Speed', '${speed.value.toStringAsFixed(1)} km/h', speed.status == SensorStatus.healthy ? AuraColors.textPrimary : AuraColors.caliperRed),
                  _paramTile('Left Wheel', '${wheelL.value.toStringAsFixed(2)} m/s', wheelL.status == SensorStatus.healthy ? AuraColors.textPrimary : AuraColors.caliperRed),
                  _paramTile('Right Wheel', '${wheelR.value.toStringAsFixed(2)} m/s', wheelR.status == SensorStatus.healthy ? AuraColors.textPrimary : AuraColors.caliperRed),
                ],
              ),
              const Divider(height: 20),
              // Compact Speed History Graph
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: speed.history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: AuraColors.metallicIceBlue,
                        barWidth: 2.2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AuraColors.metallicIceBlue.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // IMU & Acceleration Card (Yaw Rate, Accel X/Y/Z)
        AuraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('IMU MOTION DYNAMICS (MPU-6050)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _paramTile('Yaw Rate', '${yaw.value.toStringAsFixed(3)} rad/s', AuraColors.metallicIceBlue),
                  _paramTile('Accel X (Long)', '${accX.value.toStringAsFixed(2)} m/s²', Colors.white),
                  _paramTile('Accel Y (Lat)', '${accY.value.toStringAsFixed(2)} m/s²', Colors.white),
                  _paramTile('Accel Z (Vert)', '${accZ.value.toStringAsFixed(2)} m/s²', Colors.white),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Power & BMS Tab
  Widget _buildPowerTab(AuraStateProvider aura, bool isDemo, bool isWaiting) {
    final volt = aura.sensors['battery_volt']!;
    final curr = aura.sensors['battery_curr']!;
    final power = aura.sensors['power_cons']!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isWaiting) ...[
          const WaitingForVehicleBanner(),
          const SizedBox(height: 12),
        ],
        AuraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('48V HIGH-VOLTAGE BMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8)),
                  if (isDemo)
                    const Text('SIMULATED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AuraColors.metallicIceBlue)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _paramTile('Pack Voltage', '${volt.value.toStringAsFixed(2)} V', volt.status == SensorStatus.healthy ? AuraColors.healthyGreen : AuraColors.warningAmber),
                  _paramTile('Discharge Current', '${curr.value.toStringAsFixed(1)} A', curr.status == SensorStatus.healthy ? AuraColors.textPrimary : AuraColors.warningAmber),
                  _paramTile('Total Power', '${power.value.toStringAsFixed(1)} W', AuraColors.metallicIceBlue),
                ],
              ),
              const Divider(height: 20),
              // Compact Power Curve
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: power.history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: AuraColors.warningAmber,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AuraColors.warningAmber.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Proximity & Thermal Tab
  Widget _buildThermalProximityTab(AuraStateProvider aura, bool isDemo, bool isWaiting) {
    final temp = aura.sensors['temperature']!;
    final tof = aura.sensors['tof_dist']!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isWaiting) ...[
          const WaitingForVehicleBanner(),
          const SizedBox(height: 12),
        ],
        AuraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PROXIMITY & THERMAL SENSORS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _paramTile('ECU Temp', '${temp.value.toStringAsFixed(1)} °C', temp.status == SensorStatus.healthy ? AuraColors.textPrimary : AuraColors.warningAmber),
                  _paramTile('ToF Distance', '${tof.value.toStringAsFixed(2)} m', AuraColors.metallicIceBlue),
                  _paramTile('Obstacle Status', tof.value > 1.5 ? 'CLEAR' : (tof.value == 0.0 ? 'OFFLINE' : 'PROXIMITY'), tof.value > 1.5 ? AuraColors.healthyGreen : AuraColors.caliperRed),
                ],
              ),
              const Divider(height: 20),
              // Compact ToF Curve
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: tof.history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        color: AuraColors.healthyGreen,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AuraColors.healthyGreen.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paramTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AuraColors.titaniumGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color, fontFamily: 'monospace')),
      ],
    );
  }
}
