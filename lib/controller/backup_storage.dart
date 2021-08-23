import 'dart:convert';
import 'dart:io';

import 'package:lit_backup_service/model/backup_model.dart';
import 'package:lit_backup_service/model/models.dart';
import 'package:path_provider/path_provider.dart';

class BackupStorage {
  final String directoryName;
  final String subdirectoryName;
  final String fileName;

  const BackupStorage({
    required this.directoryName,
    required this.subdirectoryName,
    required this.fileName,
  });

  static const String _unimplementedErrorMessage =
      "Unimplemented platform: Could not locate suitable backup location." +
          " " +
          "Please consider that `LitBackupStorage` is only supported on Android devices.";

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<String> get currentMediaPath async {
    return await _documentsPath;
  }

  Future<String> get _documentsPath async {
    if (Platform.isAndroid) {
      return "/storage/emulated/0/Documents/";
    }
    if (Platform.isMacOS) {
      try {
        final directory = await getDownloadsDirectory();
        return directory!.path;
      } catch (e) {
        throw Exception(
          _unimplementedErrorMessage,
        );
      }
    }
    print(_unimplementedErrorMessage);
    throw Exception();
  }

  void _createStorageDir(String path) async {
    Directory('$path/$directoryName').create();
    Directory('$path/$directoryName/$subdirectoryName').create();
  }

  Future<File> get _localFile async {
    final mediaPath = await _documentsPath;
    _createStorageDir(mediaPath);
    final path = "$mediaPath$directoryName/$subdirectoryName";
    return File('$path/$fileName.json');
  }

  Future<BackupModel?> readBackup(
      {required BackupModel Function(String) decode}) async {
    final file = await _localFile;
    print("Reading from file on ${file.path}");
    try {
      // Read the file
      final contents = await file.readAsString();

      return decode(contents);
    } catch (e) {
      print("ERROR: File on ${file.path} not found!");
      return null;
    }
  }

  Future<File> writeBackup(BackupModel backup) async {
    final file = await _localFile;
    print("Writing to file on ${file.path}");

    final map = backup.toJson();

    final json = jsonEncode(map);

    //final stringifiedJson = map.toString();

    // Write the file
    return file.writeAsString(json);
  }
}
