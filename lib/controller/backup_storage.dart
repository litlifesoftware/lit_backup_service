import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

  /// States whether to use the Android's `Manage External Storage` permission.
  /// Requesting this permission will enable full access to all external storage
  /// on Android 10 (API level 29) and higher.
  /// This will enable the app access to all folders on the devices
  /// and therefore will allow backups to be restored without the user having
  /// to provide a specific backup document.
  ///
  /// This flag will be set to `false` by default because of security conserns
  /// when using the `Manage External Storage` permission. More information:
  /// https://support.google.com/googleplay/android-developer/answer/9214102#zippy=
  final bool useManageExternalStoragePermission;

  /// The backup file's extension. Defaults to [EXTENSION_JSON].
  ///
  /// File extensions allow custom file types and easier filtering when
  /// filtering for backup files.
  final String fileExtension;

  /// The `installationID` is required in order to allow varying file names
  /// when using the same app on different installations or on the different
  /// devices. One `installationID` must not match the previous installation's
  /// id in order to preserve the scoped file privilege enforced on Android
  /// 10 or higher (API 29+).
  ///
  /// In order to keep each `installationID` bound to only on installation it
  /// is recommended to create the id on the first startup of your app (clear
  /// instance or restored instance). Store the `installationID` on the primary
  /// database and update it every time the app has been re-installed.
  final String installationID;

  /// Allows to only use the `applicationName` for directory naming. Ignores
  /// the provided organization name.
  final bool useShortDirectoryNaming;

  /// Creates a [BackupStorage].
  const BackupStorage({
    required this.organizationName,
    required this.applicationName,
    required this.fileName,
    this.mediaLocation = MediaLocation.DOWNLOAD_LOCATION_ANDROID,
    this.useManageExternalStoragePermission = false,
    this.fileExtension = EXTENSION_JSON,
    required this.installationID,
    this.useShortDirectoryNaming = false,
  });

  static const String _unimplementedErrorMessage =
      "Unimplemented platform: Could not locate suitable backup location." +
          " " +
          "Please consider that `LitBackupStorage` is only supported on" +
          " " +
          "Android devices.";

  static const String _ErrorMessage =
      "ERROR: Backup not found or missing Permissions!" +
          " " +
          "Try to delete the previous backup file in order to create a updated" +
          " " +
          "backup.";

  /// The expected file system path, where backups should be stored at.
  ///
  /// Ignores platform validations.
  String get expectedBackupPath {
    if (useShortDirectoryNaming) {
      return mediaLocation.path + applicationName;
    }
    return mediaLocation.path + organizationName + '/' + applicationName;
  }

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
    if (useShortDirectoryNaming) {
      try {
        Directory('$path/$applicationName').create();
      } catch (e) {
        print(e);
      }
    } else {
      try {
        Directory('$path/$organizationName').create();
        Directory('$path/$organizationName/$applicationName').create();
      } catch (e) {
        print(e);
      }
    }
  }

  /// Creates the backup file.
  Future<File> get _localFile async {
    final mediaPath = await _mediaLocation;
    _createStorageDir(mediaPath);
    final path = useShortDirectoryNaming
        ? "$mediaPath$applicationName"
        : "$mediaPath$organizationName/$applicationName";
    return File('$path/$fileName-$installationID.$fileExtension');
  }

  /// Creates the backup file.
  Future<File> _createLocalFile(String cachedPath) async {
    return File(cachedPath);
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
      print("Backup found on ${file.path}");
      return decode(contents);
    } catch (e) {
      print(_ErrorMessage);
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
      print(_ErrorMessage);
      print(e.toString());
      return;
    }
  }

  /// Evaluates whether all required permissions have been granted.
  ///
  /// Returns `false` by default.
  Future<bool> hasPermissions() async {
    var statusStorage = await Permission.storage.status;
    var statusManageStorage = await Permission.manageExternalStorage.status;

    if (useManageExternalStoragePermission) {
      if (statusStorage.isGranted && statusManageStorage.isGranted) return true;
    } else {
      if (statusStorage.isGranted) return true;
    }

    return false;
  }

  /// Request all required permissions to access the existing backup files
  /// stored on the Media locations.
  ///
  Future<void> requestPermissions() async {
    // Mandatory `EXTERNAL STORAGE` permission.
    var statusStorage = await Permission.storage.status;
    if (!statusStorage.isGranted) await Permission.storage.request();

    // Optional `MANAGE EXTERNAL STORAGE` permission on API 29+.
    if (useManageExternalStoragePermission) {
      var statusManageStorage = await Permission.manageExternalStorage.status;
      if (!statusManageStorage.isGranted)
        await Permission.manageExternalStorage.request();
    }
  }

  /// Shows the platform's native file explorer in order to pick a specific
  /// backup file.
  ///
  /// If the requested [fileExtension] is not supported on the platform, no
  /// file extension filter will be applied.
  Future<BackupModel?> pickBackupFile({
    /// The serialization logic.
    ///
    /// The logic will vary from Model class to Model class and must be
    /// provided on each read-request.
    required BackupModel Function(String) decode,
  }) async {
    FilePickerResult? result;

    try {
      // Allow extension filtering
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [fileExtension],
      );
    } catch (e) {
      // Use default
      result = await FilePicker.platform.pickFiles();
      print("File Extention '$fileExtension' not supported on this device.");
      print(e);
    }

    if (result != null) {
      PlatformFile pickedfile = result.files.first;

      if (pickedfile.path == null) {
        print("Unable to locate file");
        return null;
      }

      print("Picked file cached at: " + pickedfile.path!);

      try {
        // Point to the cached backup file location.
        final file = await _createLocalFile(pickedfile.path!);
        // Read the file
        final contents = await file.readAsString();
        print("Backup found on ${file.path}");
        return decode(contents);
      } catch (e) {
        print(_ErrorMessage);
        print(e.toString());
        return null;
      }
    } else {
      // User canceled the picker
      print("Selecting file aborted.");
    }
  }
}
