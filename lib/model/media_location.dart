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
}
