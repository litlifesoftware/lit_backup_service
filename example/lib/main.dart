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
  TextEditingController _nameInput = TextEditingController(text: '');
  TextEditingController _quoteInput =
      TextEditingController(text: 'If you want to be happy, be.');

  ExampleBackup get exampleBackup {
    return ExampleBackup(
      name: _nameInput.text,
      quote: _quoteInput.text,
      backupDate: DateTime.now().toIso8601String(),
    );
  }

  final BackupStorage backupStorage = BackupStorage(
    organizationName: "MyOrganization",
    applicationName: "LitBackupService",
    fileName: "examplebackup",
  );

  // Write the variable as a string to the file.
  Future<void> _writeBackup(ExampleBackup backup) async {
    setState(
      () => {
        backupStorage.writeBackup(backup),
      },
    );
  }

  Future<BackupModel?> _readBackup() {
    return backupStorage.readBackup(
      decode: (contents) => ExampleBackup.fromJson(
        jsonDecode(contents),
      ),
    );
  }

  String formatAsLocalizedDate(BuildContext context, DateTime date) {
    final TimeOfDay timeOfDay = TimeOfDay.fromDateTime(date);
    final String dateFormat =
        MaterialLocalizations.of(context).formatShortDate(date);
    final String timeFormat = MaterialLocalizations.of(context).formatTimeOfDay(
      timeOfDay,
    );
    return "$dateFormat $timeFormat";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        title: Text("LitBackupService"),
      ),
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
                  onPressed: () => _writeBackup(exampleBackup),
                  child: Text("backup now"),
                ),
                _BackupPreviewBuilder(
                  backupStorage: backupStorage,
                  formatAsLocalizedDate: formatAsLocalizedDate,
                  readBackup: _readBackup(),
                ),
              ],
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
  const _BackupPreviewBuilder({
    Key? key,
    required this.backupStorage,
    required this.formatAsLocalizedDate,
    required this.readBackup,
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
                      FutureBuilder(
                        future: backupStorage.currentMediaPath,
                        builder: (context, AsyncSnapshot<String> snap) {
                          return snap.data != null
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15.0,
                                  ),
                                  child: Text(
                                    "Current media directory:\n" + snap.data!,
                                  ),
                                )
                              : SizedBox();
                        },
                      )
                    ],
                  )
                : Text("No backup found!");
          }

          if (snap.hasError) return Text("Error");
        } else if (snap.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        return Text("No backup found!");
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
