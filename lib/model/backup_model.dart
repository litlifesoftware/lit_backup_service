/// An `abstract` class defining a blueprint how backup models should be
/// structurecd.
///
/// The custom `JSON` serialization should preferably be included in each
/// model class itself. Serialization can then be performed within each
/// individual model class without the need of multiple serialization
/// controllers for each model class.

abstract class BackupModel {
  Map<String, dynamic> toJson();
}
