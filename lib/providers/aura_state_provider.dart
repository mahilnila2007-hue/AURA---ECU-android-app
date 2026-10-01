import 'package:flutter/material.dart';
import '../models/aura_models.dart';
import '../services/telemetry_source.dart';

class AuraStateProvider extends ChangeNotifier {
  AppDataMode _mode = AppDataMode.realTime;
  DemoScenario _activeScenario = DemoScenario.normal;
  bool _isDemoPaused = false;
  double _simulationSpeed = 1.0;

  // Active data sources
  late final DemoTelemetrySource _demoSource;
  late final RealTimeTelemetrySource _realTimeSource;
  TelemetrySource? _activeSource;

  // Telemetry state snapshot
  late TelemetrySnapshot _currentSnapshot;

  // OTA state
  late OtaValidationPackage _currentOta;
  List<OtaValidationPackage> _otaHistory = [];

  // Recovery Timeline
  final List<String> _recoveryTimeline = [
    "10:00:00 - Initial Safety ECU Diagnostics Passed",
    "10:00:02 - CAN Bus Synchronized (500 kbps)",
    "10:00:05 - All Virtual Sensor Kernels Active"
  ];

  // Vehicle Profile
  final String _activeVehicleName = "AURA-PROTOTYPE 01";
  final String _activeVehicleId = "VIN-AURA-2026-X9";

  // Getters
  AppDataMode get mode => _mode;
  DemoScenario get activeScenario => _activeScenario;
  bool get isDemoPaused => _isDemoPaused;
  double get simulationSpeed => _simulationSpeed;
  bool get isRealTimeWaiting => _mode == AppDataMode.realTime && !_currentSnapshot.isConnected;

  bool get canConnected => _currentSnapshot.canConnected;
  bool get fogOnline => _currentSnapshot.fogOnline;
  bool get cloudOnline => _currentSnapshot.cloudOnline;
  double get vehicleHealthScore => _currentSnapshot.vehicleHealthScore;
  double get ecuHealthScore => _currentSnapshot.ecuHealthScore;
  Map<String, SensorData> get sensors => _currentSnapshot.sensors;
  Map<String, VirtualSensorModel> get virtualSensors => _currentSnapshot.virtualSensors;
  EcuInfo get vehicleEcu => _currentSnapshot.vehicleEcu;
  EcuInfo get safetyEcu => _currentSnapshot.safetyEcu;
  List<CanFrame> get canFrames => _currentSnapshot.canFrames;
  double get canBitrateKbps => 500.0;
  double get canBusLoad => _currentSnapshot.canBusLoad;
  int get canMessageCount => _currentSnapshot.canMessageCount;
  int get canErrorCount => _currentSnapshot.canErrorCount;
  double get canSuccessRate => _currentSnapshot.canSuccessRate;
  double get fogLatencyMs => _currentSnapshot.fogLatencyMs;
  double get cloudLatencyMs => _currentSnapshot.cloudLatencyMs;
  List<FaultItem> get faults => _currentSnapshot.faults;
  RecoveryMode get recoveryMode => _currentSnapshot.recoveryMode;
  String get activeRecoveryAction => _currentSnapshot.activeRecoveryAction;
  List<String> get recoveryTimeline => _recoveryTimeline;
  OtaValidationPackage get currentOta => _currentOta;
  List<OtaValidationPackage> get otaHistory => _otaHistory;
  String get activeVehicleName => _activeVehicleName;
  String get activeVehicleId => _activeVehicleId;

  AuraStateProvider() {
    _demoSource = DemoTelemetrySource();
    _realTimeSource = RealTimeTelemetrySource();
    _initOta();
    _setSource(_realTimeSource);
  }

  void _setSource(TelemetrySource source) {
    _activeSource?.stop();
    _activeSource = source;
    _activeSource!.start((snapshot) {
      _currentSnapshot = snapshot;
      notifyListeners();
    });
  }

  // Global Mode Toggle
  void setMode(AppDataMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;

    if (_mode == AppDataMode.demo) {
      _setSource(_demoSource);
    } else {
      _setSource(_realTimeSource);
    }
    notifyListeners();
  }

  void toggleMode() {
    if (_mode == AppDataMode.demo) {
      setMode(AppDataMode.realTime);
    } else {
      setMode(AppDataMode.demo);
    }
  }

  // Demo Scenarios
  void setScenario(DemoScenario scenario) {
    _activeScenario = scenario;
    _demoSource.setScenario(scenario);

    // Apply OTA specific scenarios if selected
    if (scenario == DemoScenario.otaValidationPass) {
      validateOtaPackage(forcePass: true);
    } else if (scenario == DemoScenario.otaValidationFail) {
      validateOtaPackage(forcePass: false);
    } else if (scenario == DemoScenario.autoRollback) {
      rollbackOta();
    }
    notifyListeners();
  }

  void _initOta() {
    _currentOta = OtaValidationPackage(
      version: 'v3.2.0-STABLE',
      targetEcu: 'ECU-S-AURA (Safety Recovery Engine)',
      releaseDate: DateTime.now().subtract(const Duration(days: 1)),
      sizeKb: 1420,
      signaturePass: true,
      integrityPass: true,
      compatibilityPass: true,
      canTimingPass: true,
      memoryReqPass: true,
      sandboxPass: true,
      riskLevel: 'LOW',
      confidenceScore: 98.4,
      status: OtaStatus.validated,
      releaseNotes: 'Enhances virtual sensor Kalman filter convergence time by 18ms and adds anti-drift compensation for Hall sensors.',
    );

    _otaHistory = [
      OtaValidationPackage(
        version: 'v3.1.0-aura',
        targetEcu: 'ECU-S-AURA',
        releaseDate: DateTime.now().subtract(const Duration(days: 14)),
        sizeKb: 1380,
        signaturePass: true,
        integrityPass: true,
        compatibilityPass: true,
        canTimingPass: true,
        memoryReqPass: true,
        sandboxPass: true,
        riskLevel: 'LOW',
        confidenceScore: 99.1,
        status: OtaStatus.deployed,
        releaseNotes: 'Base AURA recovery architecture deployment with CAN 2.0B listener.',
      ),
      OtaValidationPackage(
        version: 'v2.4.0-unstable',
        targetEcu: 'ECU-V-01',
        releaseDate: DateTime.now().subtract(const Duration(days: 28)),
        sizeKb: 1510,
        signaturePass: true,
        integrityPass: true,
        compatibilityPass: false,
        canTimingPass: false,
        memoryReqPass: true,
        sandboxPass: false,
        riskLevel: 'HIGH',
        confidenceScore: 42.0,
        status: OtaStatus.rejected,
        releaseNotes: 'Experimental timing scheduler - Rejected due to CAN bus jitter exceeding 12ms limit.',
      ),
    ];
  }

  // OTA Actions
  void validateOtaPackage({bool forcePass = true}) {
    _currentOta = OtaValidationPackage(
      version: forcePass ? 'v3.2.0-STABLE' : 'v3.2.1-UNSTABLE',
      targetEcu: 'ECU-S-AURA',
      releaseDate: DateTime.now(),
      sizeKb: forcePass ? 1420 : 1450,
      signaturePass: true,
      integrityPass: true,
      compatibilityPass: forcePass,
      canTimingPass: forcePass,
      memoryReqPass: true,
      sandboxPass: forcePass,
      riskLevel: forcePass ? 'LOW' : 'HIGH',
      confidenceScore: forcePass ? 98.4 : 32.0,
      status: forcePass ? OtaStatus.validated : OtaStatus.failed,
      releaseNotes: forcePass
          ? 'Validation PASSED on all automotive safety & timing gates.'
          : 'SECURITY CRITICAL: Fails CAN bus timing deadline in sandbox simulation (14.2ms > 10.0ms limit). Deployment blocked.',
    );
    notifyListeners();
  }

  void approveOta() {
    if (_currentOta.status == OtaStatus.validated || _currentOta.status == OtaStatus.pending) {
      _currentOta = OtaValidationPackage(
        version: _currentOta.version,
        targetEcu: _currentOta.targetEcu,
        releaseDate: _currentOta.releaseDate,
        sizeKb: _currentOta.sizeKb,
        signaturePass: _currentOta.signaturePass,
        integrityPass: _currentOta.integrityPass,
        compatibilityPass: _currentOta.compatibilityPass,
        canTimingPass: _currentOta.canTimingPass,
        memoryReqPass: _currentOta.memoryReqPass,
        sandboxPass: _currentOta.sandboxPass,
        riskLevel: _currentOta.riskLevel,
        confidenceScore: _currentOta.confidenceScore,
        status: OtaStatus.validated,
        releaseNotes: _currentOta.releaseNotes,
      );
      notifyListeners();
    }
  }

  void rejectOta() {
    _currentOta = OtaValidationPackage(
      version: _currentOta.version,
      targetEcu: _currentOta.targetEcu,
      releaseDate: _currentOta.releaseDate,
      sizeKb: _currentOta.sizeKb,
      signaturePass: _currentOta.signaturePass,
      integrityPass: _currentOta.integrityPass,
      compatibilityPass: _currentOta.compatibilityPass,
      canTimingPass: _currentOta.canTimingPass,
      memoryReqPass: _currentOta.memoryReqPass,
      sandboxPass: _currentOta.sandboxPass,
      riskLevel: 'HIGH',
      confidenceScore: _currentOta.confidenceScore,
      status: OtaStatus.rejected,
      releaseNotes: 'OTA Package rejected by safety engineer. Deployment permanently halted.',
    );
    notifyListeners();
  }

  void deployOta() {
    if (_currentOta.status == OtaStatus.validated &&
        _currentOta.signaturePass &&
        _currentOta.integrityPass &&
        _currentOta.compatibilityPass &&
        _currentOta.canTimingPass &&
        _currentOta.memoryReqPass &&
        _currentOta.sandboxPass) {
      _currentOta = OtaValidationPackage(
        version: _currentOta.version,
        targetEcu: _currentOta.targetEcu,
        releaseDate: _currentOta.releaseDate,
        sizeKb: _currentOta.sizeKb,
        signaturePass: _currentOta.signaturePass,
        integrityPass: _currentOta.integrityPass,
        compatibilityPass: _currentOta.compatibilityPass,
        canTimingPass: _currentOta.canTimingPass,
        memoryReqPass: _currentOta.memoryReqPass,
        sandboxPass: _currentOta.sandboxPass,
        riskLevel: _currentOta.riskLevel,
        confidenceScore: _currentOta.confidenceScore,
        status: OtaStatus.deployed,
        releaseNotes: _currentOta.releaseNotes,
      );
      _otaHistory.insert(0, _currentOta);
      _recoveryTimeline.insert(0, "${DateTime.now().toIso8601String().substring(11, 19)} - OTA Firmware ${_currentOta.version} Deployed to ${_currentOta.targetEcu}");
      notifyListeners();
    }
  }

  void rollbackOta() {
    _currentOta = OtaValidationPackage(
      version: 'v3.1.0-GOLDEN-RESTORED',
      targetEcu: 'ECU-S-AURA',
      releaseDate: DateTime.now(),
      sizeKb: 1380,
      signaturePass: true,
      integrityPass: true,
      compatibilityPass: true,
      canTimingPass: true,
      memoryReqPass: true,
      sandboxPass: true,
      riskLevel: 'LOW',
      confidenceScore: 99.8,
      status: OtaStatus.rolledBack,
      releaseNotes: 'Dual-Bank Flash Rollback: Reverted to golden image v3.1.0.',
    );
    _recoveryTimeline.insert(0, "${DateTime.now().toIso8601String().substring(11, 19)} - Safety ECU executed Dual-Bank Flash Rollback to Golden Image");
    notifyListeners();
  }

  void executeRecoveryAction(String action) {
    _recoveryTimeline.insert(0, "${DateTime.now().toIso8601String().substring(11, 19)} - Triggered: $action");
    notifyListeners();
  }

  @override
  void dispose() {
    _activeSource?.stop();
    super.dispose();
  }
}
