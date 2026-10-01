enum AppDataMode { demo, realTime }
enum DemoScenario {
  normal,
  wheelSensorFail,
  mpu6050Abnormal,
  canCommFail,
  batteryAbnormal,
  temperatureRise,
  softwareFault,
  otaValidationPass,
  otaValidationFail,
  autoRollback
}

enum SensorStatus { healthy, warning, fault, offline, virtualActive }
enum EcuStatus { online, degraded, offline, recovery, safeMode }
enum FaultSeverity { info, warning, high, critical }
enum RecoveryMode { normal, degraded, safe, recovery, rollback }
enum OtaStatus { validated, deployed, rejected, rolledBack, pending, validating, failed }

class SensorData {
  final String id;
  final String name;
  final double value;
  final String unit;
  final SensorStatus status;
  final double health; // 0 to 100%
  final double signalQuality; // 0 to 100%
  final int faultCount;
  final double frequencyHz;
  final double rawValue;
  final double filteredValue;
  final DateTime timestamp;
  final List<double> history;

  SensorData({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
    required this.health,
    required this.signalQuality,
    required this.faultCount,
    required this.frequencyHz,
    required this.rawValue,
    required this.filteredValue,
    required this.timestamp,
    required this.history,
  });

  SensorData copyWith({
    String? id,
    String? name,
    double? value,
    String? unit,
    SensorStatus? status,
    double? health,
    double? signalQuality,
    int? faultCount,
    double? frequencyHz,
    double? rawValue,
    double? filteredValue,
    DateTime? timestamp,
    List<double>? history,
  }) {
    return SensorData(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      health: health ?? this.health,
      signalQuality: signalQuality ?? this.signalQuality,
      faultCount: faultCount ?? this.faultCount,
      frequencyHz: frequencyHz ?? this.frequencyHz,
      rawValue: rawValue ?? this.rawValue,
      filteredValue: filteredValue ?? this.filteredValue,
      timestamp: timestamp ?? this.timestamp,
      history: history ?? this.history,
    );
  }
}

class VirtualSensorModel {
  final String parameter;
  final double physicalValue;
  final double estimatedValue;
  final double difference;
  final double error;
  final double confidence; // e.g. 96.4%
  final String status;
  final String reconstructionFormula;
  final double mae;
  final double rmse;
  final double mape;
  final bool isVirtualActive;

  VirtualSensorModel({
    required this.parameter,
    required this.physicalValue,
    required this.estimatedValue,
    required this.difference,
    required this.error,
    required this.confidence,
    required this.status,
    required this.reconstructionFormula,
    required this.mae,
    required this.rmse,
    required this.mape,
    required this.isVirtualActive,
  });
}

class EcuInfo {
  final String name;
  final String id;
  final bool isOnline;
  final double cpuLoad; // %
  final double memoryUsage; // %
  final double temperature; // °C
  final int canTrafficMessages;
  final String firmwareVersion;
  final Duration uptime;
  final double healthScore;
  final String activeMode;

  EcuInfo({
    required this.name,
    required this.id,
    required this.isOnline,
    required this.cpuLoad,
    required this.memoryUsage,
    required this.temperature,
    required this.canTrafficMessages,
    required this.firmwareVersion,
    required this.uptime,
    required this.healthScore,
    required this.activeMode,
  });
}

class CanFrame {
  final String id; // Hex e.g. 0x180
  final DateTime timestamp;
  final int dlc;
  final String dataHex;
  final String sourceEcu;
  final String destinationEcu;
  final String description;

  CanFrame({
    required this.id,
    required this.timestamp,
    required this.dlc,
    required this.dataHex,
    required this.sourceEcu,
    required this.destinationEcu,
    required this.description,
  });
}

class FaultItem {
  final String id;
  final String title;
  final FaultSeverity severity;
  final String affectedSensor;
  final String affectedEcu;
  final String rootCauseCategory;
  final DateTime firstDetected;
  final DateTime lastDetected;
  final String recoveryStatus;
  final Map<String, double> rootCauseProbabilities;

  FaultItem({
    required this.id,
    required this.title,
    required this.severity,
    required this.affectedSensor,
    required this.affectedEcu,
    required this.rootCauseCategory,
    required this.firstDetected,
    required this.lastDetected,
    required this.recoveryStatus,
    required this.rootCauseProbabilities,
  });
}

class OtaValidationPackage {
  final String version;
  final String targetEcu;
  final DateTime releaseDate;
  final int sizeKb;
  final bool signaturePass;
  final bool integrityPass;
  final bool compatibilityPass;
  final bool canTimingPass;
  final bool memoryReqPass;
  final bool sandboxPass;
  final String riskLevel; // LOW, MEDIUM, HIGH
  final double confidenceScore;
  final OtaStatus status;
  final String releaseNotes;

  OtaValidationPackage({
    required this.version,
    required this.targetEcu,
    required this.releaseDate,
    required this.sizeKb,
    required this.signaturePass,
    required this.integrityPass,
    required this.compatibilityPass,
    required this.canTimingPass,
    required this.memoryReqPass,
    required this.sandboxPass,
    required this.riskLevel,
    required this.confidenceScore,
    required this.status,
    required this.releaseNotes,
  });
}
