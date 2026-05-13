import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class BackupFileService {
  Future<String?> exportBackup(String backupJson) {
    return FilePicker.saveFile(
      dialogTitle: 'Export CashCheetah backup',
      fileName: _backupFileName(),
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(backupJson)),
    );
  }

  Future<String?> pickBackupJson() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Import CashCheetah backup',
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      throw Exception('Could not read the selected backup file.');
    }

    return utf8.decode(bytes);
  }
}

String _backupFileName() {
  final now = DateTime.now();
  final date = [
    now.year.toString().padLeft(4, '0'),
    now.month.toString().padLeft(2, '0'),
    now.day.toString().padLeft(2, '0'),
  ].join('');
  final time = [
    now.hour.toString().padLeft(2, '0'),
    now.minute.toString().padLeft(2, '0'),
    now.second.toString().padLeft(2, '0'),
  ].join('');

  return 'cashcheetah-backup-$date-$time.json';
}
