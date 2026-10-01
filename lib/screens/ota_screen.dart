import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/aura_state_provider.dart';
import '../theme/aura_theme.dart';
import '../widgets/aura_ui_components.dart';
import '../models/aura_models.dart';

class OtaScreen extends StatelessWidget {
  const OtaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final aura = context.watch<AuraStateProvider>();
    final ota = aura.currentOta;

    final canDeploy = ota.status == OtaStatus.validated &&
        ota.signaturePass &&
        ota.integrityPass &&
        ota.compatibilityPass &&
        ota.canTimingPass &&
        ota.memoryReqPass &&
        ota.sandboxPass;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Current OTA Package Card
          _buildOtaPackageOverview(ota),
          const SizedBox(height: 14),

          // 2. OTA Pipeline Stages (Package -> Signature -> Integrity -> Compatibility -> Sandbox -> Risk -> Approval -> Deploy -> Monitor -> Rollback)
          _buildPipelineProgress(ota),
          const SizedBox(height: 14),

          // 3. 6 Safety Validation Gates
          const Text(
            'SECURE AUTOMOTIVE SAFETY GATES',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          AuraCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                _gateRow('1. RSA-4096 Digital Signature', ota.signaturePass),
                _gateRow('2. SHA-256 Binary Integrity Check', ota.integrityPass),
                _gateRow('3. ECU Hardware Pinout & Architecture', ota.compatibilityPass),
                _gateRow('4. CAN Bus 10ms Deadline Timing Simulation', ota.canTimingPass),
                _gateRow('5. RAM Heap & Dual-Bank Flash Budget', ota.memoryReqPass),
                _gateRow('6. Isolated Virtual Sandbox Replay', ota.sandboxPass),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Action Buttons: VALIDATE, APPROVE, REJECT, DEPLOY, ROLLBACK
          const Text(
            'OTA LIFECYCLE CONTROLS',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          _buildActionButtons(context, aura, ota, canDeploy),
          const SizedBox(height: 16),

          // 5. Historical OTA Log
          _buildOtaHistory(aura),
          const SizedBox(height: 16),

          // 6. System Operating Mode Configuration (Real-Time / Demo Mode)
          _buildOperatingModeCard(aura),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildOperatingModeCard(AuraStateProvider aura) {
    final isDemo = aura.mode == AppDataMode.demo;
    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isDemo ? Icons.sensors_rounded : Icons.bolt_rounded,
                    color: isDemo ? AuraColors.metallicIceBlue : AuraColors.healthyGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TELEMETRY DATA SOURCE MODE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AuraColors.titaniumGrey,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              GlobalModeBadge(
                mode: aura.mode,
                isConnected: aura.canConnected,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isDemo
                ? 'Simulated CAN Bus & safety state telemetry actively driven by internal scenario engine.'
                : 'Live CAN bus & hardware sensor telemetry stream. Displays 0 / waiting if hardware is disconnected.',
            style: const TextStyle(fontSize: 11.5, color: AuraColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE MODE:',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AuraColors.titaniumGrey),
              ),
              GlobalModeToggle(
                currentMode: aura.mode,
                onModeChanged: (newMode) => aura.setMode(newMode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtaPackageOverview(OtaValidationPackage ota) {
    Color statusColor;
    switch (ota.status) {
      case OtaStatus.validated:
        statusColor = AuraColors.healthyGreen;
        break;
      case OtaStatus.deployed:
        statusColor = AuraColors.metallicIceBlue;
        break;
      case OtaStatus.rejected:
      case OtaStatus.failed:
        statusColor = AuraColors.caliperRed;
        break;
      default:
        statusColor = AuraColors.warningAmber;
    }

    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: AuraColors.metallicIceBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(ota.version, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              StatusBadge(label: ota.status.name.toUpperCase(), color: statusColor),
            ],
          ),
          const SizedBox(height: 6),
          Text('Target: ${ota.targetEcu} • Size: ${ota.sizeKb} KB', style: const TextStyle(fontSize: 11, color: AuraColors.titaniumGrey)),
          const SizedBox(height: 8),
          Text(ota.releaseNotes, style: const TextStyle(fontSize: 11.5, color: AuraColors.textSecondary, height: 1.3)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _metricCol('Validation Gate', ota.status == OtaStatus.failed ? 'FAIL' : 'PASS', ota.status == OtaStatus.failed ? AuraColors.caliperRed : AuraColors.healthyGreen),
              _metricCol('Risk Level', ota.riskLevel, ota.riskLevel == 'LOW' ? AuraColors.healthyGreen : AuraColors.caliperRed),
              _metricCol('Confidence', '${ota.confidenceScore.toStringAsFixed(1)}%', AuraColors.metallicIceBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCol(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: AuraColors.titaniumGrey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color, fontFamily: 'monospace')),
      ],
    );
  }

  Widget _buildPipelineProgress(OtaValidationPackage ota) {
    final stages = [
      'Package',
      'Signature',
      'Integrity',
      'Compat',
      'Sandbox',
      'Risk',
      'Approval',
      'Deploy',
      'Monitor',
      'Rollback'
    ];

    return AuraCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OTA VALIDATION & DEPLOYMENT PIPELINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: stages.map((st) {
                final isDone = ota.status == OtaStatus.deployed || (ota.status == OtaStatus.validated && st != 'Deploy' && st != 'Monitor' && st != 'Rollback');
                final color = isDone ? AuraColors.healthyGreen : AuraColors.titaniumGrey;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone ? AuraColors.healthyGreen.withValues(alpha: 0.15) : AuraColors.bgSurface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        st,
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: isDone ? AuraColors.healthyGreen : AuraColors.titaniumGrey),
                      ),
                    ),
                    if (st != stages.last)
                      const Icon(Icons.chevron_right_rounded, size: 14, color: AuraColors.borderSubtle),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gateRow(String title, bool pass) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w500)),
          Row(
            children: [
              Icon(pass ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 14, color: pass ? AuraColors.healthyGreen : AuraColors.caliperRed),
              const SizedBox(width: 4),
              Text(
                pass ? 'PASS' : 'FAIL',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: pass ? AuraColors.healthyGreen : AuraColors.caliperRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AuraStateProvider aura, OtaValidationPackage ota, bool canDeploy) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionButton(
                title: 'VALIDATE',
                icon: Icons.fact_check_rounded,
                color: AuraColors.metallicIceBlue,
                onTap: () => aura.validateOtaPackage(forcePass: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                title: 'APPROVE',
                icon: Icons.thumb_up_alt_rounded,
                color: AuraColors.healthyGreen,
                onTap: () => aura.approveOta(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionButton(
                title: 'REJECT',
                icon: Icons.thumb_down_alt_rounded,
                color: AuraColors.warningAmber,
                onTap: () => aura.rejectOta(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canDeploy ? AuraColors.deepCrimson : AuraColors.bgCard,
                    foregroundColor: canDeploy ? Colors.white : AuraColors.titaniumGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: canDeploy ? AuraColors.caliperRed : AuraColors.borderSubtle),
                  ),
                  icon: const Icon(Icons.flash_on_rounded, size: 18),
                  label: const Text('DEPLOY TO ECU FLASH', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                  onPressed: canDeploy
                      ? () {
                          aura.deployOta();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Firmware deployed to Dual-Bank Flash.')),
                          );
                        }
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AuraColors.caliperRed,
                    side: const BorderSide(color: AuraColors.caliperRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('ROLLBACK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  onPressed: () {
                    aura.rollbackOta();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Automatic dual-bank rollback executed.')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AuraColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AuraColors.borderSubtle),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildOtaHistory(AuraStateProvider aura) {
    return AuraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DEPLOYMENT & REJECTION LOG', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AuraColors.titaniumGrey, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          ...aura.otaHistory.take(2).map((h) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${h.version} (${h.targetEcu})', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  StatusBadge(
                    label: h.status.name.toUpperCase(),
                    color: h.status == OtaStatus.deployed ? AuraColors.metallicIceBlue : AuraColors.caliperRed,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
