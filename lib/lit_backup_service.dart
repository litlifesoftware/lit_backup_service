// Copyright 2021 LitLifeSoftware. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A Flutter package to create and restore backups, whose content is formatted
/// as a JSON files.
///
/// To use, import `package:lit_backup_service/lit_backup_service.dart`.
///
/// Dependencies used:
///
/// * `path_provider`
///
/// To use the above mentioned dependencies, please include them
/// separatly on the `pubspec.yaml` of your project. These will not be
/// exported to avoid namespace issues.
library lit_backup_service;

export 'model/models.dart';
export 'controller/controllers.dart';
export 'data/data.dart';
