import 'dart:async';
import 'dart:math';
import '../models/aura_models.dart';

class TelemetrySnapshot {
  final Map<String, SensorData> sensors;
  final Map<String, VirtualSensorModel> virtualSensors;
  final EcuInfo vehicleEcu;
  final EcuInfo safetyEcu;
  final List<CanFrame> canFrames;
  final double vehicleHealthScore;
  final double ecuHealthScore;
  final bool canConnected;
  final bool fogOnline;
  final bool cloudOnline;
  final double canBusLoad;
  final int canMessageCount;
  final int canErrorCount;
  final double canSuccessRate;
  final double fogLatencyMs;
  final double cloudLatencyMs;
  final RecoveryMode recoveryMode;
  final String activeRecoveryAction;
  final List<FaultItem> faults;
  final bool isConnected;
  final DateTime timestamp;

  TelemetrySnapshot({
    required this.sensors,
    required this.virtualSensors,
    required this.vehicleEcu,
    required this.safetyEcu,
    required this.canFrames,
    required this.vehicleHealthScore,
    required this.ecuHealthScore,
    required this.canConnected,
    required this.fogOnline,
    required this.cloudOnline,
    required this.canBusLoad,
    required this.canMessageCount,
    required this.canErrorCount,
    required this.canSuccessRate,
    required this.fogLatencyMs,
    required this.cloudLatencyMs,
    required this.recoveryMode,
    required this.activeRecoveryAction,
    required this.faults,
    required this.isConnected,
    required this.timestamp,
  });
}

abstract class TelemetrySource {
  void start(void Function(TelemetrySnapshot snapshot) onData);
  void stop();
  bool get isConnected;
}

/// Generates realistic, correlated, time-dependent simulated vehicle telemetry
class DemoTelemetrySource implements TelemetrySource {
  void Function(TelemetrySnapshot snapshot)? _listener;
  Timer? _ticker;
  double _simTime = 0.0;
  DemoScenario _activeScenario = DemoScenario.normal;
  final double _wheelTrackWidthM = 1.45;
  final List<CanFrame> _canFrames = [];
  int _canMessageCount = 12480;
  int _canErrorCount = 0;

  DemoScenario get activeScenario => _activeScenario;

  void setScenario(DemoScenario scenario) {
    _activeScenario = scenario;
    _emitCurrent();
  }

  @override
  bool get isConnected => true;

  @override
  void start(void Function(TelemetrySnapshot snapshot) onData) {
    _listener = onData;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _tick();
    });
    _emitCurrent();
  }

  @override
  void stop() {
    _ticker?.cancel();
    _ticker = null;
    _listener = null;
  }

  void _tick() {
    _simTime += 0.5;
    _emitCurrent();
  }

  void _emitCurrent() {
    if (_listener == null) return;
    final r = Random();

    // Correlated physics model
    final baseSpeed = 42.0 + sin(_simTime * 0.2) * 6.0 + (r.nextDouble() - 0.5) * 0.4;
    final wheelLeft = (baseSpeed / 3.6) + sin(_simTime * 0.1) * 0.1;
    final yaw = sin(_simTime * 0.15) * 0.04;
    final wheelRightTrue = wheelLeft + (yaw * _wheelTrackWidthM);
    final accelX = (baseSpeed - 40.0) * 0.08;
    final accelY = yaw * 1.6;
    final battVolt = 48.2 + (r.nextDouble() - 0.5) * 0.15;
    final battCurr = 14.5 + (baseSpeed * 0.12);
    final powerW = battVolt * battCurr;
    final tempC = 41.5 + sin(_simTime * 0.05) * 1.5;
    final tofDistM = max(0.8, 3.8 + sin(_simTime * 0.25) * 1.8);

    // Scenario specific behaviors
    Map<String, SensorData> sensors = {};
    Map<String, VirtualSensorModel> virtualSensors = {};
    List<FaultItem> faults = [];
    RecoveryMode recoveryMode = RecoveryMode.normal;
    String recoveryAction = "SYSTEM OPTIMAL - ALL SENSORS VALID";
    double vehHealth = 98.5;
    double ecuHealth = 97.8;
    bool canConn = true;
    double canSuccess = 99.98;

    if (_activeScenario == DemoScenario.wheelSensorFail) {
      sensors = _generateSensors(
        speed: baseSpeed,
        wheelL: wheelLeft,
        wheelR: 0.0,
        wheelRStatus: SensorStatus.fault,
        yaw: yaw,
        accelX: accelX,
        accelY: accelY,
        battVolt: battVolt,
        battCurr: battCurr,
        power: powerW,
        temp: tempC,
        tof: tofDistM,
      );

      final vREst = wheelLeft + (yaw * _wheelTrackWidthM);
      virtualSensors = _generateVirtualSensors(
        speedTrue: baseSpeed,
        speedEst: baseSpeed * 0.998,
        wheelLTrue: wheelLeft,
        wheelLEst: wheelLeft * 1.001,
        wheelRTrue: 0.0,
        wheelREst: vREst,
        wheelRVirtualActive: true,
        yawTrue: yaw,
        yawEst: yaw * 1.02,
      );

      faults.add(
        FaultItem(
          id: 'FLT-082',
          title: 'Right Hall Speed Sensor Loss of Signal',
          severity: FaultSeverity.high,
          affectedSensor: 'Hall Right (Wheel Speed)',
          affectedEcu: 'ECU-V-01',
          rootCauseCategory: 'Sensor Fault',
          firstDetected: DateTime.now().subtract(const Duration(seconds: 45)),
          lastDetected: DateTime.now(),
          recoveryStatus: 'Virtual Sensor Injected',
          rootCauseProbabilities: {
            'Sensor Fault': 0.74,
            'Wiring Harness Open': 0.18,
            'CAN Bus Glitch': 0.05,
            'Power Rail Drop': 0.03,
          },
        ),
      );
      vehHealth = 88.2;
      recoveryMode = RecoveryMode.degraded;
      recoveryAction = "VIRTUAL ESTIMATION ACTIVE: Hall Right isolated";
    } else if (_activeScenario == DemoScenario.canCommFail) {
      sensors = _generateSensors(
        speed: baseSpeed,
        wheelL: wheelLeft,
        wheelR: wheelRightTrue,
        yaw: yaw,
        accelX: accelX,
        accelY: accelY,
        battVolt: battVolt,
        battCurr: battCurr,
        power: powerW,
        temp: tempC,
        tof: tofDistM,
      );
      virtualSensors = _generateVirtualSensors(
        speedTrue: baseSpeed,
        speedEst: baseSpeed,
        wheelLTrue: wheelLeft,
        wheelLEst: wheelLeft,
        wheelRTrue: wheelRightTrue,
        wheelREst: wheelRightTrue,
        wheelRVirtualActive: false,
        yawTrue: yaw,
        yawEst: yaw,
      );
      canConn = false;
      _canErrorCount += 12;
      canSuccess = 84.5;
      faults.add(
        FaultItem(
          id: 'FLT-033',
          title: 'CAN Bus A Dominant Error Frame Flood',
          severity: FaultSeverity.critical,
          affectedSensor: 'CAN Bus Controller (MCP2515)',
          affectedEcu: 'ECU-V-01 & ECU-S-AURA',
          rootCauseCategory: 'CAN Fault',
          firstDetected: DateTime.now().subtract(const Duration(seconds: 10)),
          lastDetected: DateTime.now(),
          recoveryStatus: 'Switching to Redundant Channel B',
          rootCauseProbabilities: {
            'CAN Bus Short / Termination': 0.68,
            'Transceiver Failure': 0.21,
            'ECU Buffer Overflow': 0.11,
          },
        ),
      );
      recoveryMode = RecoveryMode.safe;
      recoveryAction = "CAN ERROR FLOOD: Fail-safe mode engaged";
      vehHealth = 72.0;
    } else if (_activeScenario == DemoScenario.batteryAbnormal) {
      sensors = _generateSensors(
        speed: baseSpeed * 0.8,
        wheelL: wheelLeft * 0.8,
        wheelR: wheelRightTrue * 0.8,
        yaw: yaw,
        accelX: accelX,
        accelY: accelY,
        battVolt: 39.2,
        battVoltStatus: SensorStatus.warning,
        battCurr: 38.5,
        battCurrStatus: SensorStatus.warning,
        power: 39.2 * 38.5,
        temp: tempC + 4.0,
        tof: tofDistM,
      );
      virtualSensors = _generateVirtualSensors(
        speedTrue: baseSpeed * 0.8,
        speedEst: baseSpeed * 0.8,
        wheelLTrue: wheelLeft * 0.8,
        wheelLEst: wheelLeft * 0.8,
        wheelRTrue: wheelRightTrue * 0.8,
        wheelREst: wheelRightTrue * 0.8,
        wheelRVirtualActive: false,
        yawTrue: yaw,
        yawEst: yaw,
      );
      faults.add(
        FaultItem(
          id: 'FLT-104',
          title: 'BMS Pack Voltage Under-Threshold (<40V)',
          severity: FaultSeverity.high,
          affectedSensor: 'Battery Pack Voltage Sensor',
          affectedEcu: 'ECU-V-01',
          rootCauseCategory: 'Power Fault',
          firstDetected: DateTime.now().subtract(const Duration(seconds: 20)),
          lastDetected: DateTime.now(),
          recoveryStatus: 'Power Throttling Mode (50% max torque)',
          rootCauseProbabilities: {
            'Cell Imbalance / Depletion': 0.62,
            'Current Sensor Drift': 0.25,
            'BMS Sense Wire Fault': 0.13,
          },
        ),
      );
      recoveryMode = RecoveryMode.degraded;
      recoveryAction = "POWER LIMITATION: Degraded propulsion profile";
      vehHealth = 82.0;
    } else if (_activeScenario == DemoScenario.temperatureRise) {
      sensors = _generateSensors(
        speed: baseSpeed,
        wheelL: wheelLeft,
        wheelR: wheelRightTrue,
        yaw: yaw,
        accelX: accelX,
        accelY: accelY,
        battVolt: battVolt,
        battCurr: battCurr,
        power: powerW,
        temp: 74.5,
        tempStatus: SensorStatus.warning,
        tof: tofDistM,
      );
      virtualSensors = _generateVirtualSensors(
        speedTrue: baseSpeed,
        speedEst: baseSpeed,
        wheelLTrue: wheelLeft,
        wheelLEst: wheelLeft,
        wheelRTrue: wheelRightTrue,
        wheelREst: wheelRightTrue,
        wheelRVirtualActive: false,
        yawTrue: yaw,
        yawEst: yaw,
      );
      faults.add(
        FaultItem(
          id: 'FLT-209',
          title: 'ECU Heatsink Thermal Limit Warning (>70°C)',
          severity: FaultSeverity.warning,
          affectedSensor: 'NTC Thermistor Channel 1',
          affectedEcu: 'ECU-V-01',
          rootCauseCategory: 'Thermal Fault',
          firstDetected: DateTime.now().subtract(const Duration(seconds: 30)),
          lastDetected: DateTime.now(),
          recoveryStatus: 'Cooling Pump 100% PWM + Clock Scaling',
          rootCauseProbabilities: {
            'High Ambient / Heavy Load': 0.58,
            'Cooling Loop Flow Restriction': 0.32,
            'Sensor Calibration Drift': 0.10,
          },
        ),
      );
      recoveryMode = RecoveryMode.degraded;
      recoveryAction = "THERMAL MITIGATION: Cooling PWM 100%";
      vehHealth = 85.0;
    } else if (_activeScenario == DemoScenario.softwareFault) {
      sensors = _generateSensors(
        speed: baseSpeed,
        wheelL: wheelLeft,
        wheelR: wheelRightTrue,
        yaw: yaw,
        accelX: accelX,
        accelY: accelY,
        battVolt: battVolt,
        battCurr: battCurr,
        power: powerW,
        temp: tempC,
        tof: tofDistM,
      );
      virtualSensors = _generateVirtualSensors(
        speedTrue: baseSpeed,
        speedEst: baseSpeed,
        wheelLTrue: wheelLeft,
        wheelLEst: wheelLeft,
        wheelRTrue: wheelRightTrue,
        wheelREst: wheelRightTrue,
        wheelRVirtualActive: false,
        yawTrue: yaw,
        yawEst: yaw,
      );
      faults.add(
        FaultItem(
          id: 'FLT-501',
          title: 'Safety Task Deadlock Watchdog Expiry',
          severity: FaultSeverity.critical,
          affectedSensor: 'Task Scheduler Kernel',
          affectedEcu: 'ECU-V-01',
          rootCauseCategory: 'Software Fault',
          firstDetected: DateTime.now().subtract(const Duration(seconds: 5)),
          lastDetected: DateTime.now(),
          recoveryStatus: 'Autonomous Warm Restart Executed',
          rootCauseProbabilities: {
            'Scheduler Priority Inversion': 0.65,
            'Stack Buffer Overflow': 0.25,
            'Memory Leak': 0.10,
          },
        ),
      );
      recoveryMode = RecoveryMode.recovery;
      recoveryAction = "AUTONOMOUS RESTART: Restoring state from FRAM";
      ecuHealth = 78.0;
    } else {
      // Normal Operation
      sensors = _generateSensors(
        speed: baseSpeed,
        wheelL: wheelLeft,
        wheelR: wheelRightTrue,
        yaw: yaw,
        accelX: accelX,
        accelY: accelY,
        battVolt: battVolt,
        battCurr: battCurr,
        power: powerW,
        temp: tempC,
        tof: tofDistM,
      );
      virtualSensors = _generateVirtualSensors(
        speedTrue: baseSpeed,
        speedEst: baseSpeed * 0.998,
        wheelLTrue: wheelLeft,
        wheelLEst: wheelLeft * 1.002,
        wheelRTrue: wheelRightTrue,
        wheelREst: wheelRightTrue * 0.999,
        wheelRVirtualActive: false,
        yawTrue: yaw,
        yawEst: yaw * 1.01,
      );
    }

    _generateCanFrame();

    final vEcu = EcuInfo(
      name: 'Primary Vehicle ECU',
      id: 'ECU-V-01',
      isOnline: true,
      cpuLoad: 28.4 + (sin(_simTime * 0.4) * 4.0).abs(),
      memoryUsage: 41.2,
      temperature: tempC,
      canTrafficMessages: 8420 + (_simTime * 2).toInt(),
      firmwareVersion: 'v2.4.1-rc3',
      uptime: Duration(seconds: 16330 + _simTime.toInt()),
      healthScore: ecuHealth,
      activeMode: 'NORMAL_DRIVE',
    );

    final sEcu = EcuInfo(
      name: 'Safety & Recovery ECU (AURA)',
      id: 'ECU-S-AURA',
      isOnline: true,
      cpuLoad: 34.8 + (cos(_simTime * 0.3) * 3.0).abs(),
      memoryUsage: 48.0,
      temperature: tempC - 2.0,
      canTrafficMessages: 12480 + (_simTime * 3).toInt(),
      firmwareVersion: 'v3.1.0-aura',
      uptime: Duration(seconds: 16335 + _simTime.toInt()),
      healthScore: 99.1,
      activeMode: 'ACTIVE_OBSERVER',
    );

    _listener!(
      TelemetrySnapshot(
        sensors: sensors,
        virtualSensors: virtualSensors,
        vehicleEcu: vEcu,
        safetyEcu: sEcu,
        canFrames: List.from(_canFrames),
        vehicleHealthScore: vehHealth,
        ecuHealthScore: ecuHealth,
        canConnected: canConn,
        fogOnline: true,
        cloudOnline: true,
        canBusLoad: 34.2 + sin(_simTime * 0.1) * 5.0,
        canMessageCount: _canMessageCount,
        canErrorCount: _canErrorCount,
        canSuccessRate: canSuccess,
        fogLatencyMs: 2.4 + (r.nextDouble() * 0.5),
        cloudLatencyMs: 38.6 + (r.nextDouble() * 4.0),
        recoveryMode: recoveryMode,
        activeRecoveryAction: recoveryAction,
        faults: faults,
        isConnected: true,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _generateCanFrame() {
    final r = Random();
    final ids = ['0x180', '0x184', '0x220', '0x301', '0x4A0'];
    final selectedId = ids[r.nextInt(ids.length)];
    String data = "";
    for (int i = 0; i < 8; i++) {
      data += (r.nextInt(256)).toRadixString(16).padLeft(2, '0').toUpperCase() + (i < 7 ? " " : "");
    }
    _canFrames.insert(
      0,
      CanFrame(
        id: selectedId,
        timestamp: DateTime.now(),
        dlc: 8,
        dataHex: data,
        sourceEcu: selectedId.startsWith('0x1') ? 'ECU-V-01' : 'ECU-S-AURA',
        destinationEcu: 'BROADCAST',
        description: selectedId == '0x180' ? 'Wheel Speeds (L/R)' : (selectedId == '0x184' ? 'IMU Yaw & Accel' : 'BMS Pack Voltage'),
      ),
    );
    if (_canFrames.length > 50) _canFrames.removeLast();
    _canMessageCount += 1;
  }

  Map<String, SensorData> _generateSensors({
    required double speed,
    required double wheelL,
    required double wheelR,
    SensorStatus wheelRStatus = SensorStatus.healthy,
    required double yaw,
    required double accelX,
    required double accelY,
    required double battVolt,
    SensorStatus battVoltStatus = SensorStatus.healthy,
    required double battCurr,
    SensorStatus battCurrStatus = SensorStatus.healthy,
    required double power,
    required double temp,
    SensorStatus tempStatus = SensorStatus.healthy,
    required double tof,
  }) {
    List<double> hist(double current, double range) {
      return List.generate(8, (i) => current - range * (7 - i) / 7.0 + (Random().nextDouble() - 0.5) * (range * 0.1));
    }

    return {
      'speed': SensorData(
        id: 'speed',
        name: 'Vehicle Speed',
        value: double.parse(speed.toStringAsFixed(1)),
        unit: 'km/h',
        status: SensorStatus.healthy,
        health: 99.4,
        signalQuality: 98.2,
        faultCount: 0,
        frequencyHz: 50.0,
        rawValue: speed + 0.05,
        filteredValue: speed,
        timestamp: DateTime.now(),
        history: hist(speed, 5.0),
      ),
      'wheel_l': SensorData(
        id: 'wheel_l',
        name: 'Left Wheel Speed',
        value: double.parse(wheelL.toStringAsFixed(2)),
        unit: 'm/s',
        status: SensorStatus.healthy,
        health: 99.1,
        signalQuality: 97.8,
        faultCount: 0,
        frequencyHz: 100.0,
        rawValue: wheelL + 0.01,
        filteredValue: wheelL,
        timestamp: DateTime.now(),
        history: hist(wheelL, 1.5),
      ),
      'wheel_r': SensorData(
        id: 'wheel_r',
        name: 'Right Wheel Speed',
        value: double.parse(wheelR.toStringAsFixed(2)),
        unit: 'm/s',
        status: wheelRStatus,
        health: wheelRStatus == SensorStatus.healthy ? 98.9 : 0.0,
        signalQuality: wheelRStatus == SensorStatus.healthy ? 97.4 : 0.0,
        faultCount: wheelRStatus == SensorStatus.healthy ? 0 : 4,
        frequencyHz: 100.0,
        rawValue: wheelRStatus == SensorStatus.healthy ? wheelR + 0.01 : 0.0,
        filteredValue: wheelR,
        timestamp: DateTime.now(),
        history: wheelRStatus == SensorStatus.healthy ? hist(wheelR, 1.5) : [11.5, 11.2, 8.0, 3.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'yaw_rate': SensorData(
        id: 'yaw_rate',
        name: 'Yaw Rate',
        value: double.parse(yaw.toStringAsFixed(3)),
        unit: 'rad/s',
        status: SensorStatus.healthy,
        health: 99.6,
        signalQuality: 99.0,
        faultCount: 0,
        frequencyHz: 100.0,
        rawValue: yaw + 0.001,
        filteredValue: yaw,
        timestamp: DateTime.now(),
        history: hist(yaw, 0.03),
      ),
      'acc_x': SensorData(
        id: 'acc_x',
        name: 'Acceleration X',
        value: double.parse(accelX.toStringAsFixed(2)),
        unit: 'm/s²',
        status: SensorStatus.healthy,
        health: 99.2,
        signalQuality: 98.0,
        faultCount: 0,
        frequencyHz: 100.0,
        rawValue: accelX + 0.02,
        filteredValue: accelX,
        timestamp: DateTime.now(),
        history: hist(accelX, 0.4),
      ),
      'acc_y': SensorData(
        id: 'acc_y',
        name: 'Acceleration Y',
        value: double.parse(accelY.toStringAsFixed(2)),
        unit: 'm/s²',
        status: SensorStatus.healthy,
        health: 99.0,
        signalQuality: 97.5,
        faultCount: 0,
        frequencyHz: 100.0,
        rawValue: accelY + 0.01,
        filteredValue: accelY,
        timestamp: DateTime.now(),
        history: hist(accelY, 0.2),
      ),
      'acc_z': SensorData(
        id: 'acc_z',
        name: 'Acceleration Z',
        value: 9.81,
        unit: 'm/s²',
        status: SensorStatus.healthy,
        health: 99.9,
        signalQuality: 99.2,
        faultCount: 0,
        frequencyHz: 100.0,
        rawValue: 9.82,
        filteredValue: 9.81,
        timestamp: DateTime.now(),
        history: [9.81, 9.80, 9.82, 9.81, 9.81, 9.82, 9.81, 9.81],
      ),
      'battery_volt': SensorData(
        id: 'battery_volt',
        name: 'Battery Voltage',
        value: double.parse(battVolt.toStringAsFixed(2)),
        unit: 'V',
        status: battVoltStatus,
        health: battVoltStatus == SensorStatus.healthy ? 98.5 : 55.0,
        signalQuality: 99.5,
        faultCount: battVoltStatus == SensorStatus.healthy ? 0 : 1,
        frequencyHz: 10.0,
        rawValue: battVolt + 0.02,
        filteredValue: battVolt,
        timestamp: DateTime.now(),
        history: hist(battVolt, 1.0),
      ),
      'battery_curr': SensorData(
        id: 'battery_curr',
        name: 'Battery Current',
        value: double.parse(battCurr.toStringAsFixed(1)),
        unit: 'A',
        status: battCurrStatus,
        health: battCurrStatus == SensorStatus.healthy ? 98.0 : 60.0,
        signalQuality: 98.5,
        faultCount: battCurrStatus == SensorStatus.healthy ? 0 : 1,
        frequencyHz: 20.0,
        rawValue: battCurr + 0.1,
        filteredValue: battCurr,
        timestamp: DateTime.now(),
        history: hist(battCurr, 4.0),
      ),
      'power_cons': SensorData(
        id: 'power_cons',
        name: 'Power Consumption',
        value: double.parse(power.toStringAsFixed(1)),
        unit: 'W',
        status: SensorStatus.healthy,
        health: 98.2,
        signalQuality: 98.0,
        faultCount: 0,
        frequencyHz: 20.0,
        rawValue: power + 2.0,
        filteredValue: power,
        timestamp: DateTime.now(),
        history: hist(power, 150.0),
      ),
      'temperature': SensorData(
        id: 'temperature',
        name: 'ECU Temperature',
        value: double.parse(temp.toStringAsFixed(1)),
        unit: '°C',
        status: tempStatus,
        health: tempStatus == SensorStatus.healthy ? 99.0 : 65.0,
        signalQuality: 99.0,
        faultCount: 0,
        frequencyHz: 2.0,
        rawValue: temp,
        filteredValue: temp,
        timestamp: DateTime.now(),
        history: hist(temp, 3.0),
      ),
      'tof_dist': SensorData(
        id: 'tof_dist',
        name: 'ToF Distance',
        value: double.parse(tof.toStringAsFixed(2)),
        unit: 'm',
        status: SensorStatus.healthy,
        health: 97.5,
        signalQuality: 96.0,
        faultCount: 0,
        frequencyHz: 30.0,
        rawValue: tof + 0.02,
        filteredValue: tof,
        timestamp: DateTime.now(),
        history: hist(tof, 1.0),
      ),
    };
  }

  Map<String, VirtualSensorModel> _generateVirtualSensors({
    required double speedTrue,
    required double speedEst,
    required double wheelLTrue,
    required double wheelLEst,
    required double wheelRTrue,
    required double wheelREst,
    required bool wheelRVirtualActive,
    required double yawTrue,
    required double yawEst,
  }) {
    return {
      'wheel_r': VirtualSensorModel(
        parameter: 'Right Wheel Speed (v_R)',
        physicalValue: wheelRTrue,
        estimatedValue: double.parse(wheelREst.toStringAsFixed(2)),
        difference: (wheelRTrue - wheelREst).abs(),
        error: wheelRVirtualActive ? 0.28 : 0.17,
        confidence: 96.4,
        status: wheelRVirtualActive ? 'VIRTUAL SENSOR ACTIVE' : 'STANDBY PARALLEL',
        reconstructionFormula: r'v_R_est = v_L + (r \cdot W)',
        mae: 0.08,
        rmse: 0.12,
        mape: 0.94,
        isVirtualActive: wheelRVirtualActive,
      ),
      'wheel_l': VirtualSensorModel(
        parameter: 'Left Wheel Speed (v_L)',
        physicalValue: wheelLTrue,
        estimatedValue: double.parse(wheelLEst.toStringAsFixed(2)),
        difference: (wheelLTrue - wheelLEst).abs(),
        error: 0.15,
        confidence: 97.1,
        status: 'STANDBY PARALLEL',
        reconstructionFormula: r'v_L_est = v_R - (r \cdot W)',
        mae: 0.07,
        rmse: 0.11,
        mape: 0.88,
        isVirtualActive: false,
      ),
      'yaw_rate': VirtualSensorModel(
        parameter: 'Yaw Rate (r)',
        physicalValue: yawTrue,
        estimatedValue: double.parse(yawEst.toStringAsFixed(3)),
        difference: (yawTrue - yawEst).abs(),
        error: 0.05,
        confidence: 95.4,
        status: 'STANDBY PARALLEL',
        reconstructionFormula: r'r_est = \frac{v_R - v_L}{W}',
        mae: 0.003,
        rmse: 0.005,
        mape: 1.2,
        isVirtualActive: false,
      ),
      'speed': VirtualSensorModel(
        parameter: 'Vehicle Speed (v)',
        physicalValue: speedTrue,
        estimatedValue: double.parse(speedEst.toStringAsFixed(1)),
        difference: (speedTrue - speedEst).abs(),
        error: 0.04,
        confidence: 98.9,
        status: 'STANDBY PARALLEL',
        reconstructionFormula: r'v_est = \frac{v_L + v_R}{2} \cdot 3.6',
        mae: 0.15,
        rmse: 0.22,
        mape: 0.52,
        isVirtualActive: false,
      ),
    };
  }
}

/// Real-Time telemetry source: when no hardware is connected, telemetry strictly resets to zero
class RealTimeTelemetrySource implements TelemetrySource {
  void Function(TelemetrySnapshot snapshot)? _listener;
  bool _hardwareConnected = false;
  DateTime? _lastConnectedTime;

  @override
  bool get isConnected => _hardwareConnected;
  DateTime? get lastConnectedTime => _lastConnectedTime;

  void simulateHardwareConnection(bool connected) {
    _hardwareConnected = connected;
    if (connected) {
      _lastConnectedTime = DateTime.now();
    }
    _emitCurrent();
  }

  @override
  void start(void Function(TelemetrySnapshot snapshot) onData) {
    _listener = onData;
    _emitCurrent();
  }

  @override
  void stop() {
    _listener = null;
  }

  void _emitCurrent() {
    if (_listener == null) return;

    if (!_hardwareConnected) {
      // STRICT REQUIREMENT 3 & 13:
      // When REAL-TIME MODE is ON and hardware is not connected:
      // DO NOT generate any simulated data.
      // All telemetry values must remain 0.
      _listener!(_buildZeroSnapshot());
    }
  }

  TelemetrySnapshot _buildZeroSnapshot() {
    final now = DateTime.now();

    final zeroSensors = <String, SensorData>{
      'speed': SensorData(
        id: 'speed',
        name: 'Vehicle Speed',
        value: 0.0,
        unit: 'km/h',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'wheel_l': SensorData(
        id: 'wheel_l',
        name: 'Left Wheel Speed',
        value: 0.0,
        unit: 'm/s',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'wheel_r': SensorData(
        id: 'wheel_r',
        name: 'Right Wheel Speed',
        value: 0.0,
        unit: 'm/s',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'yaw_rate': SensorData(
        id: 'yaw_rate',
        name: 'Yaw Rate',
        value: 0.0,
        unit: 'rad/s',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'acc_x': SensorData(
        id: 'acc_x',
        name: 'Acceleration X',
        value: 0.0,
        unit: 'm/s²',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'acc_y': SensorData(
        id: 'acc_y',
        name: 'Acceleration Y',
        value: 0.0,
        unit: 'm/s²',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'acc_z': SensorData(
        id: 'acc_z',
        name: 'Acceleration Z',
        value: 0.0,
        unit: 'm/s²',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'battery_volt': SensorData(
        id: 'battery_volt',
        name: 'Battery Voltage',
        value: 0.0,
        unit: 'V',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'battery_curr': SensorData(
        id: 'battery_curr',
        name: 'Battery Current',
        value: 0.0,
        unit: 'A',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'power_cons': SensorData(
        id: 'power_cons',
        name: 'Power Consumption',
        value: 0.0,
        unit: 'W',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'temperature': SensorData(
        id: 'temperature',
        name: 'ECU Temperature',
        value: 0.0,
        unit: '°C',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
      'tof_dist': SensorData(
        id: 'tof_dist',
        name: 'ToF Distance',
        value: 0.0,
        unit: 'm',
        status: SensorStatus.offline,
        health: 0.0,
        signalQuality: 0.0,
        faultCount: 0,
        frequencyHz: 0.0,
        rawValue: 0.0,
        filteredValue: 0.0,
        timestamp: now,
        history: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ),
    };

    final zeroVirtualSensors = <String, VirtualSensorModel>{
      'wheel_r': VirtualSensorModel(
        parameter: 'Right Wheel Speed (v_R)',
        physicalValue: 0.0,
        estimatedValue: 0.0,
        difference: 0.0,
        error: 0.0,
        confidence: 0.0,
        status: 'OFFLINE - NO HARDWARE STREAM',
        reconstructionFormula: r'v_R_est = v_L + (r \cdot W)',
        mae: 0.0,
        rmse: 0.0,
        mape: 0.0,
        isVirtualActive: false,
      ),
      'wheel_l': VirtualSensorModel(
        parameter: 'Left Wheel Speed (v_L)',
        physicalValue: 0.0,
        estimatedValue: 0.0,
        difference: 0.0,
        error: 0.0,
        confidence: 0.0,
        status: 'OFFLINE - NO HARDWARE STREAM',
        reconstructionFormula: r'v_L_est = v_R - (r \cdot W)',
        mae: 0.0,
        rmse: 0.0,
        mape: 0.0,
        isVirtualActive: false,
      ),
      'yaw_rate': VirtualSensorModel(
        parameter: 'Yaw Rate (r)',
        physicalValue: 0.0,
        estimatedValue: 0.0,
        difference: 0.0,
        error: 0.0,
        confidence: 0.0,
        status: 'OFFLINE - NO HARDWARE STREAM',
        reconstructionFormula: r'r_est = \frac{v_R - v_L}{W}',
        mae: 0.0,
        rmse: 0.0,
        mape: 0.0,
        isVirtualActive: false,
      ),
      'speed': VirtualSensorModel(
        parameter: 'Vehicle Speed (v)',
        physicalValue: 0.0,
        estimatedValue: 0.0,
        difference: 0.0,
        error: 0.0,
        confidence: 0.0,
        status: 'OFFLINE - NO HARDWARE STREAM',
        reconstructionFormula: r'v_est = \frac{v_L + v_R}{2} \cdot 3.6',
        mae: 0.0,
        rmse: 0.0,
        mape: 0.0,
        isVirtualActive: false,
      ),
    };

    final offlineVehicleEcu = EcuInfo(
      name: 'Primary Vehicle ECU',
      id: 'ECU-V-01',
      isOnline: false,
      cpuLoad: 0.0,
      memoryUsage: 0.0,
      temperature: 0.0,
      canTrafficMessages: 0,
      firmwareVersion: 'N/A (DISCONNECTED)',
      uptime: Duration.zero,
      healthScore: 0.0,
      activeMode: 'OFFLINE',
    );

    final offlineSafetyEcu = EcuInfo(
      name: 'Safety & Recovery ECU (AURA)',
      id: 'ECU-S-AURA',
      isOnline: false,
      cpuLoad: 0.0,
      memoryUsage: 0.0,
      temperature: 0.0,
      canTrafficMessages: 0,
      firmwareVersion: 'N/A (DISCONNECTED)',
      uptime: Duration.zero,
      healthScore: 0.0,
      activeMode: 'OFFLINE',
    );

    return TelemetrySnapshot(
      sensors: zeroSensors,
      virtualSensors: zeroVirtualSensors,
      vehicleEcu: offlineVehicleEcu,
      safetyEcu: offlineSafetyEcu,
      canFrames: [],
      vehicleHealthScore: 0.0,
      ecuHealthScore: 0.0,
      canConnected: false,
      fogOnline: false,
      cloudOnline: false,
      canBusLoad: 0.0,
      canMessageCount: 0,
      canErrorCount: 0,
      canSuccessRate: 0.0,
      fogLatencyMs: 0.0,
      cloudLatencyMs: 0.0,
      recoveryMode: RecoveryMode.normal,
      activeRecoveryAction: "WAITING FOR VEHICLE HARDWARE...",
      faults: [],
      isConnected: false,
      timestamp: now,
    );
  }
}
