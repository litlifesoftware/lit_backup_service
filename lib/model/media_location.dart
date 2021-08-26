/// A location on the local device's file system.
///
/// It does include a path pointing to a specific folder.

class MediaLocation {
  /// The location's path on the file system.
  final String path;

  /// Creates a [MediaLocation].
  const MediaLocation({
    required this.path,
  });

  /// A [MediaLocation] pointing the the `Documents` Media folder on `Android`
  /// devices.
  static const MediaLocation DOCUMENTS_LOCATION_ANDROID =
      MediaLocation(path: "/storage/emulated/0/Documents/");

  /// A [MediaLocation] pointing the the `Download` Media folder on `Android`
  /// devices.
  static const MediaLocation DOWNLOAD_LOCATION_ANDROID =
      MediaLocation(path: "/storage/emulated/0/Download/");
}
