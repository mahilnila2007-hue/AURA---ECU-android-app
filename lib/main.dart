import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/aura_theme.dart';
import 'providers/aura_state_provider.dart';
import 'screens/home_screen.dart';
import 'screens/vehicle_screen.dart';
import 'screens/diagnostics_screen.dart';
import 'screens/recovery_screen.dart';
import 'screens/ota_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AuraEcuApp());
}

class AuraEcuApp extends StatelessWidget {
  const AuraEcuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuraStateProvider()),
      ],
      child: MaterialApp(
        title: 'AURA-ECU',
        debugShowCheckedModeBanner: false,
        theme: AuraTheme.darkTheme,
        home: const MainNavigationShell(),
      ),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    VehicleScreen(),
    DiagnosticsScreen(),
    RecoveryScreen(),
    OtaScreen(),
  ];

  final List<String> _screenTitles = const [
    'SYSTEM DASHBOARD',
    'VEHICLE TELEMETRY',
    'DIAGNOSTICS & FAULTS',
    'ADAPTIVE RECOVERY',
    'OTA VALIDATION GATE',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 62,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AuraColors.deepCrimson,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AuraColors.caliperRed, width: 1),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AURA-ECU',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
                ),
                Text(
                  _screenTitles[_currentIndex],
                  style: const TextStyle(fontSize: 9.5, color: AuraColors.titaniumGrey, letterSpacing: 0.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AuraColors.borderSubtle, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car_rounded),
              label: 'VEHICLE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.troubleshoot_rounded),
              activeIcon: Icon(Icons.troubleshoot_rounded),
              label: 'DIAGNOSTICS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.healing_outlined),
              activeIcon: Icon(Icons.healing_rounded),
              label: 'RECOVERY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.system_update_alt_rounded),
              activeIcon: Icon(Icons.system_update_alt_rounded),
              label: 'OTA',
            ),
          ],
        ),
      ),
    );
  }
}
