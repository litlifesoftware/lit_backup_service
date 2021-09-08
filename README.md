# LitBackupService

> [![lit_backup_service][lit_backup_service_badge_pub]][lit_backup_service] [![pub points][lit_backup_service_badge_pub_points]][lit_backup_service_pub_points]

by [LitLifeSoftware](https://github.com/litlifesoftware)

## What is LitBackupService?

LitBackupService is a Flutter package allowing you to create and restore backups using
JSON files. This package does implement a very simple persistent (key-value pair) storage on local devices and should only be used as a secondary storage solution (such as for backuping other databases).

It does contain an abstract model class to provide a basic structure
how backupable model classes should be defined. The JSON serialization should
therefore be performed on each model class individually, as the models varies in
structure.

## Platform Support

| Android |
| :-----: |
|   ✔️    |

This package is currently only supported on Android devices.

## Screenshots

| Example HomeScreen | Example HomeScreen |
| ------------------ | ------------------ |
| ![1][screenshot_1] | ![2][screenshot_2] |

## Required Permissions on Android

In order to read and write outside the app-specific directories, additional
permissions must be granted. These must be enabled on the `AndroidManifest.xml`
of your app located on `android/app/src/main`.

```xml
// Android devices prior to Android 11
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
// Optional on Android devices from Android 11
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```
Enabling the required permissions will be done using the `BackupStorage`'s
`requestPermissions()` method, which utilizes the `permission_handler` package.

More recent releases of `Android`
are managing storage permissions on the [file's purpose](https://developer.android.com/training/data-storage#permissions) and have some restrictions. In order to access already existing backup files created using previous installations
on Android 10 and higher, the `MANAGE_EXTERNAL_STORAGE` permissions must be granted.
The current installation won't be able to access them directly due to the altered
file privileges. This must be specified on the `BackupStorage`'s `useManageExternalStoragePermission`
flag. This practice is discouraged. Use the `BackupStorage`'s `pickBackupFile()`
methods to allow picking a specific file without the need of additional permissions.

## Backup Location

Backups are stored on the device's Media directories by default. But custom file
paths are supported. The Media directories will include the Documents folder
(default) on `/storage/emulated/0/Documents/` or the Download folder on
`/storage/emulated/0/Download/`.

We recommend to use the Documents folder
as backup location if possible for better security.

But for higher compatibility we recommend to use the `Download` folder, due
to it being available on almost all Android devices.

## Getting Started

This project is a starting point for a Dart
[package](https://flutter.dev/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Example app

To get a better understanding for implementing the LitBackupService, we recommend
to take a look at the example app provided in the `example` folder. Feel free to
experiment with the app.

## Dependencies

LitBackupService uses the following Dart dependencies in order to implement certain
features and functionality:

- [permission_handler](https://pub.dev/packages/permission_handler) - [License](https://github.com/Baseflow/flutter-permission-handler/blob/master/LICENSE) (Used to request storage access permissions)
- [file_picker](https://pub.dev/packages/file_picker) - [License](https://github.com/miguelpruivo/flutter_file_picker/blob/master/LICENSE) (Used to allow platform-specific file picking)

## Credits

LitBackupService is made possible thanks to the Flutter Project.

## License

Everything else in this repository including the source code is distributed under the
**BSD 3-Clause** license as specified in the `LICENSE` file.

[screenshot_1]: assets/screenshots/Screenshot_1.png
[screenshot_2]: assets/screenshots/Screenshot_2.png
[lit_backup_service]: https://pub.dev/packages/lit_backup_service
[lit_backup_service_pub_points]: https://pub.dev/packages/lit_backup_service/score
[lit_backup_service_badge_pub]: https://img.shields.io/pub/v/lit_backup_service.svg
[lit_backup_service_badge_pub_points]: https://badges.bar/lit_backup_service/pub%20points
