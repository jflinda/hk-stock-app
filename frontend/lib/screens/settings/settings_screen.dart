import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hk_stock_app/constants/index.dart';
import 'package:hk_stock_app/services/api_service.dart';
import 'package:path_provider/path_provider.dart';

/// Settings Screen - User preferences and configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String language = 'English';
  bool darkMode = true;
  bool dailyNotification = true;
  bool priceAlert = true;
  bool pnlUpdate = true;
  bool newsNotification = false;
  bool _exportingCSV = false;

  // ── CSV Export ──────────────────────────────────────────────────────────────
  Future<void> _exportCSV() async {
    setState(() => _exportingCSV = true);
    try {
      final csvData = await apiService.exportTradesCSV();

      // Save to app documents directory (always accessible without special permissions)
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'hk_trades_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to ${file.path}'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.green.withOpacity(0.85),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingCSV = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        backgroundColor: AppColors.darkBg,
      ),
      body: ListView(
        children: [
          // Profile Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.accentBlue,
                  child: const Text('JL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('John Liu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('jlinda@example.com', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Member since Mar 2026', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),

          // Display Settings
          _SettingSection(
            title: 'Display',
            children: [
              _SettingTile(
                title: 'Language',
                subtitle: 'Choose app language',
                trailing: DropdownButton(
                  value: language,
                  underline: Container(),
                  items: ['English', '繁體中文', '简体中文']
                      .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                      .toList(),
                  onChanged: (value) => setState(() => language = value!),
                ),
              ),
              _SwitchTile(
                title: 'Dark Mode',
                subtitle: 'Always on',
                value: darkMode,
                onChanged: (value) => setState(() => darkMode = value),
              ),
              _SettingTile(
                title: 'Chart Type',
                subtitle: 'Candlestick (default)',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),

          // Notifications
          _SettingSection(
            title: 'Notifications',
            children: [
              _SwitchTile(
                title: 'Daily Market Summary',
                subtitle: '9:00 AM every trading day',
                value: dailyNotification,
                onChanged: (value) => setState(() => dailyNotification = value),
              ),
              _SwitchTile(
                title: 'Price Alerts',
                subtitle: 'When your watchlist stocks hit targets',
                value: priceAlert,
                onChanged: (value) => setState(() => priceAlert = value),
              ),
              _SwitchTile(
                title: 'P&L Updates',
                subtitle: 'When positions change significantly',
                value: pnlUpdate,
                onChanged: (value) => setState(() => pnlUpdate = value),
              ),
              _SwitchTile(
                title: 'Financial News',
                subtitle: 'Latest market news',
                value: newsNotification,
                onChanged: (value) => setState(() => newsNotification = value),
              ),
            ],
          ),

          // Data & Privacy
          _SettingSection(
            title: 'Data & Privacy',
            children: [
              _SettingTile(
                title: 'Export Data',
                subtitle: 'Download all trades as CSV',
                trailing: _exportingCSV
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download, color: AppColors.accentBlue),
                onTap: _exportingCSV ? null : _exportCSV,
              ),
              _SettingTile(
                title: 'Backup',
                subtitle: 'Cloud backup not configured',
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
              _SettingTile(
                title: 'Clear Data',
                subtitle: 'Delete all trades and positions',
                textColor: AppColors.downColor,
                onTap: () => _showClearDataDialog(context),
              ),
            ],
          ),

          // About
          _SettingSection(
            title: 'About',
            children: [
              _SettingTile(
                title: 'Version',
                subtitle: 'App Version',
                trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              _SettingTile(
                title: 'Data Source',
                subtitle: 'Real-time stock data',
                trailing: const Text('Yahoo Finance', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              _SettingTile(
                title: 'Terms of Service',
                subtitle: 'Read our terms',
                trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 18),
              ),
              _SettingTile(
                title: 'Privacy Policy',
                subtitle: 'How we protect your data',
                trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully')),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.downColor,
                side: const BorderSide(color: AppColors.downColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Sign Out'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This action cannot be undone. All trades, positions, and watchlists will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.downColor)),
          ),
        ],
      ),
    );
  }
}

class _SettingSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentBlue, fontSize: 12)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accentBlue,
          ),
        ],
      ),
    );
  }
}
