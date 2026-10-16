import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../dashboard/dashboard_screen.dart';
import '../alerts/alerts_screen.dart';
import '../stock/add_product_screen.dart';
import '../sales/sales_logger_screen.dart';
import '../insights/insights_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/data_management_screen.dart';
import '../../data/settings.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AddProductScreen(),
    const SalesLoggerScreen(),
    const AlertsScreen(),
    const InsightsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkBackupReminder();
  }

  Future<void> _checkBackupReminder() async {
    final settingsBox = Hive.box<AppSettings>('settings');
    final settings = settingsBox.get(0);

    if (settings != null && settings.backupEnabled) {
      final lastBackup = settings.lastBackupDate;
      final now = DateTime.now();

      if (lastBackup == null || now.difference(lastBackup).inDays >= 7) {
        // Show backup reminder after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showBackupReminder();
          }
        });
      }
    }
  }

  void _showBackupReminder() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Reminder'),
        content: const Text(
          'It\'s been 7 days since your last backup. Consider backing up your data to keep it safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to data management screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DataManagementScreen(),
                ),
              );
            },
            child: const Text('Backup Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
