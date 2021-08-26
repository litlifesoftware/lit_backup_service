import 'dart:convert';
import 'dart:io';

import 'package:lit_backup_service/data/data.dart';
import 'package:lit_backup_service/model/models.dart';
import 'package:permission_handler/permission_handler.dart';

/// A `controller` class handling read and write operations of backups to
/// local storage.
///
/// Backups are preferably stored on the device's Media directories
/// ([MediaLocation]). The [organizationName] will be a directory in the Media
/// directory, 	whereas the [applicationName] will be a subdirectory (inside the
/// [organizationName] directory). This will help the user to organize different
/// backups of different applications.
///
/// A `organizationName` of `MyOrganization`,  a `applicationName` of `MyApp`
/// and a `fileName` of `examplebackup` on the `Documents` media directory would
/// compound a complete path of
/// `/storage/emulated/0/Documents/MyOrganization/MyApp/examplebackup.json`.
///
class BackupStorage {
  /// The application's creator.
  final String organizationName;

  /// The application's name.
  final String applicationName;

  /// The file's name. The file extention will not be required, because all
  /// backup files ẁill have the `json` extension exclusively by default.
  final String fileName;

  /// The [MediaLocation] to store the backup in.
  final MediaLocation mediaLocation;

  /// Creates a [BackupStorage].
  const BackupStorage({
    required this.organizationName,
    required this.applicationName,
    required this.fileName,
    this.mediaLocation = MediaLocation.DOWNLOAD_LOCATION_ANDROID,
  });

  static const String _unimplementedErrorMessage =
      "Unimplemented platform: Could not locate suitable backup location." +
          " " +
          "Please consider that `LitBackupStorage` is only supported on" +
          " " +
          "Android devices.";

  static const String _notFoundErrorMessage = "ERROR: Backup not found!";

  /// Retrieves the currently selected `Media` directory on the local device's
  /// file system.
  ///
  /// Throws an `Exception` if the current device does not run on `Android`.
  Future<String> get currentMediaPath async {
    return await _mediaLocation;
  }

  /// Checks the supported platform and either throws an `Exception` of the
  /// devices's media location.
  Future<String> get _mediaLocation async {
    if (Platform.isAndroid) {
      return mediaLocation.path;
    }

    print(_unimplementedErrorMessage);
    throw Exception();
  }

  /// Creates all directories required to store and retrieve backup files.
  void _createStorageDir(String path) async {
    Directory('$path/$organizationName').create();
    Directory('$path/$organizationName/$applicationName').create();
  }

  /// Creates the backup file.
  Future<File> get _localFile async {
    final mediaPath = await _mediaLocation;
    _createStorageDir(mediaPath);
    final path = "$mediaPath$organizationName/$applicationName";
    return File('$path/$fileName.$EXTENSION_JSON');
  }

  /// Reads the backup from the selected location.
  ///
  /// Returns `null` if the backup has not been found or could not be
  /// serialized.
  Future<BackupModel?> readBackup({
    /// The serialization logic.
    ///
    /// The logic will vary from Model class to Model class and must be
    /// provided on each read-request.
    required BackupModel Function(String) decode,
  }) async {
    print("Reading Backup...");
    try {
      final file = await _localFile;
      // Read the file
      final contents = await file.readAsString();
      print("Backup found on on ${file.path}");
      return decode(contents);
    } catch (e) {
      print(_notFoundErrorMessage);
      print(e.toString());
      return null;
    }
  }

  /// Creates a backup file based on the provided `BackupModel`'s content.
  Future<File> writeBackup(BackupModel backup) async {
    final File file = await _localFile;
    print("Writing Backup content to file on ${file.path}");

    // Serialize to a `Map` object on the model itself.
    final Map<String, dynamic> map = backup.toJson();

    // The encoded `JSON` content
    final String json = jsonEncode(map);

    // Write the content to the file
    return file.writeAsString(json);
  }

  /// Deletes the existing backup file.
  Future<void> deleteBackup() async {
    try {
      final file = await _localFile;
      await file.delete();
      print("Backup deleted.");
    } catch (e) {
      print(_notFoundErrorMessage);
      print(e.toString());
      return;
    }
  }

  /// Evaluates whether all required permissions have been granted.
  ///
  /// Returns `false` by default.
  Future<bool> hasPermissions() async {
    var statusStorage = await Permission.storage.status;

    if (statusStorage.isGranted) return true;

    var statusManageStorage = await Permission.manageExternalStorage.status;

    if (statusManageStorage.isGranted) return true;

    return false;
  }

  /// Request all required permissions to access the existing backup files
  /// stored on the Media locations.
  ///
  Future<void> requestPermissions() async {
    var statusStorage = await Permission.storage.status;

    var statusManageStorage = await Permission.manageExternalStorage.status;

    if (!statusStorage.isGranted) await Permission.storage.request();

    if (!statusManageStorage.isGranted)
      await Permission.manageExternalStorage.request();
  }
}
