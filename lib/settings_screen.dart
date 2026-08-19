import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'backup_file_service.dart';
import 'myprovider.dart';
import 'tutorial_screen.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final BackupFileService _backupFileService = BackupFileService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.only(bottom: 24),
          children: [
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Quick Tour'),
              subtitle: Text('Review how CashCheetah works'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => TutorialScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.file_upload_outlined),
              title: Text('Export data'),
              subtitle: Text('Save accounts and transactions as a JSON backup'),
              onTap: () => _exportData(context),
            ),
            ListTile(
              leading: Icon(Icons.file_download_outlined),
              title: Text('Import data'),
              subtitle: Text('Replace current data from a JSON backup'),
              onTap: () => _confirmAndImportData(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AccountProvider>();

    try {
      final savedPath =
          await _backupFileService.exportBackup(provider.exportBackupJson());
      if (savedPath == null) {
        return;
      }
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Backup exported.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Could not export backup.')),
      );
    }
  }

  Future<void> _confirmAndImportData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Replace current data?'),
        content: Text(
          'Importing a backup will replace all current accounts and transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Replace'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await _importData(context);
  }

  Future<void> _importData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<AccountProvider>();

    try {
      final backupJson = await _backupFileService.pickBackupJson();
      if (backupJson == null) {
        return;
      }

      await provider.replaceAllAccountsFromBackupJson(backupJson);
      if (!context.mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Backup imported.')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Could not import that backup file.')),
      );
    }
  }
}
