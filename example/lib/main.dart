import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lit_backup_service/lit_backup_service.dart';

class ExampleBackup implements BackupModel {
  final String name;
  final String quote;
  final String backupDate;

  const ExampleBackup({
    required this.name,
    required this.quote,
    required this.backupDate,
  });

  factory ExampleBackup.fromJson(Map<String, dynamic> json) {
    return ExampleBackup(
      name: json['name'] as String,
      quote: json['quote'] as String,
      backupDate: json['backupDate'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'quote': quote,
      'name': name,
      'backupDate': backupDate,
    };
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LitBackupService',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _pressedPickFile = false;

  TextEditingController _nameInput = TextEditingController(text: '');
  TextEditingController _quoteInput =
      TextEditingController(text: 'If you want to be happy, be.');

  ExampleBackup get _exampleBackup {
    return ExampleBackup(
      name: _nameInput.text,
      quote: _quoteInput.text,
      backupDate: DateTime.now().toIso8601String(),
    );
  }

  String _formatAsLocalizedDate(BuildContext context, DateTime date) {
    final TimeOfDay timeOfDay = TimeOfDay.fromDateTime(date);
    final String dateFormat =
        MaterialLocalizations.of(context).formatShortDate(date);
    final String timeFormat = MaterialLocalizations.of(context).formatTimeOfDay(
      timeOfDay,
    );
    return "$dateFormat $timeFormat";
  }

  void _onPressedPick() {
    setState(() {
      _pressedPickFile = !_pressedPickFile;
    });
  }

  final BackupStorage _backupStorage = BackupStorage(
    organizationName: "MyOrganization",
    applicationName: "LitBackupService",
    fileName: "examplebackup",
    // The installationID should be generated only once after the initial app
    // startup and be stored on a persisten data storage (such as `SQLite`) to
    // ensure the file name matches on each app startup.
    installationID: DateTime.now().millisecondsSinceEpoch.toRadixString(16),
  );

  // Write the variable as a string to the file.
  Future<void> _writeBackup(ExampleBackup backup) async {
    setState(
      () => {
        _backupStorage.writeBackup(backup),
      },
    );
  }

  Future<BackupModel?> _readBackup() {
    return _backupStorage.readBackup(
      decode: (contents) => ExampleBackup.fromJson(
        jsonDecode(contents),
      ),
    );
  }

  Future<void> _deleteBackup() async {
    setState(
      () => {
        _backupStorage.deleteBackup(),
      },
    );
  }

  Future<BackupModel?> _readBackupFromPicker() {
    return _backupStorage.pickBackupFile(
      decode: (contents) => ExampleBackup.fromJson(
        jsonDecode(contents),
      ),
    );
  }

  Future<void> _requestPermissions() async {
    _backupStorage.requestPermissions().then((value) => setState(() {}));
  }

  @override
  void dispose() {
    _pressedPickFile = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (selected) {
          setState(() {
            _currentIndex = selected;
            _pressedPickFile = false;
          });
        },
        items: [
          BottomNavigationBarItem(
            label: "Restore",
            icon: Icon(Icons.restore),
          ),
          BottomNavigationBarItem(
            label: "Create",
            icon: Icon(Icons.create),
          ),
        ],
      ),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: Text("LitBackupService"),
      ),
      body: _currentIndex == 0
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40.0,
                    horizontal: 16.0,
                  ),
                  child: FutureBuilder(
                    future: _backupStorage.hasPermissions(),
                    builder: (context, AsyncSnapshot<bool> hasPerSnap) {
                      if (hasPerSnap.connectionState == ConnectionState.done &&
                          hasPerSnap.hasData) {
                        return hasPerSnap.data!
                            ? Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: _onPressedPick,
                                    child: Text(_pressedPickFile
                                        ? "CLEAR"
                                        : "PICK BACKUP FILE"),
                                  ),
                                  _pressedPickFile
                                      ? _BackupPreviewBuilder(
                                          backupStorage: _backupStorage,
                                          formatAsLocalizedDate:
                                              _formatAsLocalizedDate,
                                          readBackup: _readBackupFromPicker(),
                                          requestPermissions:
                                              _requestPermissions,
                                        )
                                      : SizedBox(),
                                ],
                              )
                            : Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Text(
                                        "Reading backup from storage denied."),
                                  ),
                                  ElevatedButton(
                                    onPressed: _requestPermissions,
                                    child: Text("Request permissions"),
                                  ),
                                ],
                              );
                      }

                      return CircularProgressIndicator();
                    },
                  ),
                ),
              ),
            )
          : Scaffold(
              body: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      children: [
                        _InputField(
                          title: "Your name",
                          controller: _nameInput,
                        ),
                        _InputField(
                          title: "Your quote",
                          controller: _quoteInput,
                        ),
                        ElevatedButton(
                          onPressed: () => _writeBackup(_exampleBackup),
                          child: Text("BACKUP NOW"),
                        ),
                        _BackupPreviewBuilder(
                          backupStorage: _backupStorage,
                          formatAsLocalizedDate: _formatAsLocalizedDate,
                          readBackup: _readBackup(),
                          requestPermissions: _requestPermissions,
                          showMediaLocation: true,
                        ),
                        FutureBuilder(
                          future: _backupStorage.hasPermissions(),
                          builder: (context, AsyncSnapshot<bool> hasPerSnap) {
                            return hasPerSnap.hasData
                                ? hasPerSnap.data!
                                    ? ElevatedButton(
                                        onPressed: _deleteBackup,
                                        child: Text("DELETE BACKUP"),
                                      )
                                    : SizedBox()
                                : SizedBox();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _BackupPreviewBuilder extends StatelessWidget {
  final BackupStorage backupStorage;
  final String Function(BuildContext context, DateTime datetime)
      formatAsLocalizedDate;
  final Future<BackupModel?> readBackup;
  final void Function() requestPermissions;
  final bool showMediaLocation;
  const _BackupPreviewBuilder({
    Key? key,
    required this.backupStorage,
    required this.formatAsLocalizedDate,
    required this.readBackup,
    required this.requestPermissions,
    this.showMediaLocation = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: readBackup,
      builder: (context, AsyncSnapshot<BackupModel?> snap) {
        if (snap.connectionState == ConnectionState.done) {
          if (snap.hasData) {
            ExampleBackup? exampleBackup = snap.data as ExampleBackup;
            return snap.data != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Backup of ${exampleBackup.name}",
                      ),
                      Text(
                        "Quote: ${exampleBackup.quote}",
                      ),
                      Text(
                        "Last backup:" +
                            " " +
                            formatAsLocalizedDate(
                              context,
                              DateTime.parse(exampleBackup.backupDate),
                            ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 30.0,
                        ),
                        child: Text(
                          "You will find your JSON file on your" +
                              " " +
                              "selected Media directory of your" +
                              " " +
                              "local device.",
                        ),
                      ),
                      showMediaLocation
                          ? FutureBuilder(
                              future: backupStorage.currentMediaPath,
                              builder: (context, AsyncSnapshot<String> snap) {
                                return snap.data != null
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15.0,
                                        ),
                                        child: Text(
                                          "Current media directory:\n" +
                                              snap.data!,
                                        ),
                                      )
                                    : SizedBox();
                              },
                            )
                          : SizedBox()
                    ],
                  )
                : Text("No backup found!");
          }

          if (snap.hasError) return Text("Error");
        } else if (snap.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        // Permission denied or file not found.

        return FutureBuilder(
          future: backupStorage.hasPermissions(),
          builder: (context, AsyncSnapshot<bool> hasPerSnap) {
            return hasPerSnap.hasData
                ? !hasPerSnap.data!
                    ? Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text("Reading backup from storage denied."),
                          ),
                          ElevatedButton(
                            onPressed: requestPermissions,
                            child: Text("Request permissions"),
                          ),
                        ],
                      )
                    : Text(
                        "Backup not found!",
                      )
                : SizedBox();
          },
        );
      },
    );
  }
}

class _InputField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  const _InputField({
    Key? key,
    required this.title,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
      ),
      child: Column(
        children: [
          Text(title),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter your $title...',
            ),
          ),
        ],
      ),
    );
  }
}
