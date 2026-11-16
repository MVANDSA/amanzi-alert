import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

const Color skyBlue = Color(0xFF79C9EA);
const Color iceBlue = Color(0xFFBDEBFA);
const Color cloudBlue = Color(0xFFEAF8FD);
const Color oceanBlue = Color(0xFF247B9E);
const Color navy = Color(0xFF173B50);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background notification received: ${message.messageId}');
}

Future<void> setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  messaging.onRegistered.listen((installationId) {
    debugPrint('AquaLink Firebase Installation ID: $installationId');
  });

  await messaging.register();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final context = navigatorKey.currentContext;

    if (notification != null && context != null && context.mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notification.title ?? 'AquaLink Notification'),
          content: Text(notification.body ?? 'You have a new update.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notification opened: ${message.messageId}');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await setupFirebaseMessaging();

  runApp(const AquaLinkApp());
}

class AquaLinkApp extends StatelessWidget {
  const AquaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'AquaLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cloudBlue,
        colorScheme: ColorScheme.fromSeed(seedColor: oceanBlue),
        appBarTheme: const AppBarTheme(
          backgroundColor: skyBlue,
          foregroundColor: navy,
          elevation: 0,
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// DATABASE: saves reports on the phone.
class ReportDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final databaseFilePath = p.join(databasePath, 'aqualink.db');

    _database = await openDatabase(
      databaseFilePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reports (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            location TEXT,
            latitude REAL,
            longitude REAL,
            photoPath TEXT,
            status TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  static Future<int> addReport(Map<String, dynamic> report) async {
    final db = await database;
    return db.insert('reports', report);
  }

  static Future<List<Map<String, dynamic>>> getReports() async {
    final db = await database;
    return db.query('reports', orderBy: 'id DESC');
  }
}

class AquaLinkShell extends StatefulWidget {
  const AquaLinkShell({super.key});

  @override
  State<AquaLinkShell> createState() => _AquaLinkShellState();
}

class _AquaLinkShellState extends State<AquaLinkShell> {
  int selectedIndex = 0;
  int refreshNumber = 0;

  Future<void> openReportForm() async {
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ReportFormPage()),
    );

    if (submitted == true && mounted) {
      setState(() {
        selectedIndex = 2;
        refreshNumber++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onReport: openReportForm),
      const InformationPage(),
      MyReportsPage(key: ValueKey(refreshNumber)),
    ];

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            openReportForm();
          } else {
            setState(() => selectedIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'My Reports',
          ),
        ],
      ),
    );
  }
}

class AquaLinkLogo extends StatelessWidget {
  final double size;

  const AquaLinkLogo({super.key, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: oceanBlue,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.water_drop, color: Colors.white, size: size * 0.68),
          Positioned(
            bottom: size * 0.13,
            child: Icon(Icons.waves, color: skyBlue, size: size * 0.40),
          ),
        ],
      ),
    );
  }
}

// HOME SCREEN
class HomePage extends StatelessWidget {
  final VoidCallback onReport;

  const HomePage({super.key, required this.onReport});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            AquaLinkLogo(size: 38),
            SizedBox(width: 10),
            Text('AquaLink', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello, Community!',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Stay connected. Report water problems. '
              'Make a difference in your community.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [skyBlue, iceBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AquaLinkLogo(size: 55),
                  const SizedBox(height: 18),
                  const Text(
                    'Water problem in your area?',
                    style: TextStyle(
                      color: navy,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Help improve water services by reporting '
                    'leaks, outages and water quality issues.',
                    style: TextStyle(color: navy, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.add),
                    label: const Text('Report a Problem'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: oceanBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'What would you like to report?',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 14),
            const IssueCard(
              icon: Icons.plumbing,
              title: 'Water Leaks',
              description: 'Leaking pipes and burst water mains.',
            ),
            const IssueCard(
              icon: Icons.water_drop_outlined,
              title: 'Water Outages',
              description: 'Water shortages in your community.',
            ),
            const IssueCard(
              icon: Icons.warning_amber_rounded,
              title: 'Water Quality',
              description: 'Dirty, contaminated or unusual water.',
            ),
          ],
        ),
      ),
    );
  }
}

class IssueCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const IssueCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cloudBlue,
          child: Icon(icon, color: oceanBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(color: navy, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
      ),
    );
  }
}

// REPORT FORM
class ReportFormPage extends StatefulWidget {
  const ReportFormPage({super.key});

  @override
  State<ReportFormPage> createState() => _ReportFormPageState();
}

class _ReportFormPageState extends State<ReportFormPage> {
  final formKey = GlobalKey<FormState>();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final picker = ImagePicker();

  String category = 'Water Leak';
  String? photoPath;
  double? latitude;
  double? longitude;
  bool gettingLocation = false;
  bool saving = false;

  @override
  void dispose() {
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> getLocation() async {
    setState(() => gettingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Please switch on your phone location service.');
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        locationController.text = '${position.latitude}, ${position.longitude}';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => gettingLocation = false);
    }
  }

  Future<void> choosePhoto(ImageSource source) async {
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() => photoPath = pickedFile.path);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select photo: $error')),
        );
      }
    }
  }

  Future<void> saveReport() async {
    if (!formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before submitting a report.'),
        ),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final now = DateTime.now();
      final reportReference = 'AQL-${now.millisecondsSinceEpoch}';

      final reportData = {
        'reporterUid': user.uid,
        'category': category,
        'description': descriptionController.text.trim(),
        'location': locationController.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'status': 'Submitted',
        'referenceNumber': reportReference,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save the report to Firebase.
      await FirebaseFirestore.instance.collection('reports').add(reportData);

      // Keep a local copy in SQLite as well.
      await ReportDatabase.addReport({
        'category': category,
        'description': descriptionController.text.trim(),
        'location': locationController.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'photoPath': photoPath,
        'status': 'Submitted',
        'createdAt': now.toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Report submitted successfully! Reference: $reportReference',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save report: $error')));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a Water Problem')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Tell us what is happening',
              style: TextStyle(
                color: navy,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Complete the details below to submit your report.'),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(
                labelText: 'Problem category',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Water Leak',
                  child: Text('Water Leak'),
                ),
                DropdownMenuItem(
                  value: 'Water Outage',
                  child: Text('Water Outage'),
                ),
                DropdownMenuItem(
                  value: 'Water Quality',
                  child: Text('Water Quality'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => category = value);
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe the problem',
                hintText: 'Explain what happened and where...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe the water problem.';
                }
                if (value.trim().length < 10) {
                  return 'Please provide a little more detail.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location or area',
                hintText: 'Enter your street, village or area',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: gettingLocation ? null : getLocation,
              icon: const Icon(Icons.my_location),
              label: Text(
                gettingLocation ? 'Getting location...' : 'Use my GPS location',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Attach a photo (optional)',
              style: TextStyle(color: navy, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => choosePhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => choosePhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (photoPath != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photoPath!),
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => photoPath = null),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove photo'),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: saving ? null : saveReport,
                icon: const Icon(Icons.send),
                label: Text(saving ? 'Submitting...' : 'Submit Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: oceanBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MY REPORTS SCREEN

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your reports.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('reporterUid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load reports. Please try again.'),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          final reports = documents.map((document) {
            return {...document.data(), 'id': document.id};
          }).toList();

          reports.sort((a, b) {
            final dateA = _reportDate(a['createdAt']);
            final dateB = _reportDate(b['createdAt']);

            return dateB.compareTo(dateA);
          });

          if (reports.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined, size: 65, color: oceanBlue),
                    SizedBox(height: 15),
                    Text(
                      'No reports yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your submitted water problem reports will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: cloudBlue,
                    child: Icon(Icons.water_drop, color: oceanBlue),
                  ),
                  title: Text(
                    report['category'] as String? ?? 'Water Problem',
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${report['status'] ?? 'Submitted'}\n'
                    '${report['location'] ?? 'Location not provided'}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailsPage(report: report),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// REPORT DETAILS SCREEN
class ReportDetailsPage extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailsPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final photo = report['photoPath'] as String?;
    final date = _reportDate(report['createdAt']);

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            report['category'] as String? ?? 'Water Problem',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),
          const SizedBox(height: 15),
          _detailRow(
            'Reference number',
            report['referenceNumber'] as String? ?? 'Not available',
          ),
          _detailRow('Status', report['status'] as String? ?? 'Submitted'),
          _detailRow('Description', report['description'] as String? ?? ''),
          _detailRow(
            'Location',
            (report['location'] as String?)?.isNotEmpty == true
                ? report['location'] as String
                : 'Not provided',
          ),
          _detailRow('Date submitted', date.toLocal().toString().split('.')[0]),
          if (report['latitude'] != null && report['longitude'] != null)
            _detailRow(
              'GPS coordinates',
              '${report['latitude']}, ${report['longitude']}',
            ),
          if (photo != null) ...[
            const SizedBox(height: 18),
            const Text(
              'Attached photo (saved on this device)',
              style: TextStyle(fontWeight: FontWeight.bold, color: navy),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(photo),
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Photo is not available on this device.');
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: oceanBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

DateTime _reportDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime(2000);
  }

  return DateTime(2000);
}

// INFORMATION SCREEN
class InformationPage extends StatelessWidget {
  const InformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About AquaLink')),
      body: const Padding(
        padding: EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AquaLinkLogo(size: 65),
            SizedBox(height: 20),
            Text(
              'About AquaLink',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'AquaLink is a community water problem reporting '
              'application. It allows residents to record water leaks, '
              'water outages and water quality concerns. Reports can '
              'include a location and a photo, and are saved on the device.',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            SizedBox(height: 18),
            Text(
              'The aim is to make it easier for community members to '
              'document water service problems.',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// AUTHENTICATION GATE

// AUTHENTICATION GATE
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const AuthPage();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Could not load your account profile.'),
                ),
              );
            }

            if (!profileSnapshot.hasData || !profileSnapshot.data!.exists) {
              return const Scaffold(
                body: Center(
                  child: Text('Your AquaLink profile could not be found.'),
                ),
              );
            }

            final role = profileSnapshot.data!.data()?['role'] ?? 'resident';

            if (role == 'admin') {
              return const AdminDashboard();
            }

            if (role == 'agent') {
              return const AgentDashboard();
            }

            return const AquaLinkShell();
          },
        );
      },
    );
  }
}

// LOGIN AND REGISTRATION
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isRegistering = false;
  bool loading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address first.'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'If an account exists for this email, a password reset link has been sent. Please check your inbox.',
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Could not send password reset email.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final auth = FirebaseAuth.instance;

      if (isRegistering) {
        final credential = await auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final user = credential.user!;

        await user.updateDisplayName(nameController.text.trim());

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': nameController.text.trim(),
          'email': emailController.text.trim(),
          'role': 'resident',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authentication failed.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Something went wrong: $error')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AquaLinkLogo(size: 75),
                  const SizedBox(height: 18),
                  const Text(
                    'Welcome to AquaLink',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRegistering
                        ? 'Create an account to report water problems.'
                        : 'Sign in to connect with your water services.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  if (isRegistering) ...[
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Please enter your full name.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                              .hasMatch(value.trim())) {
                        return 'Enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => hidePassword = !hidePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must have at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  if (!isRegistering)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading ? null : resetPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: oceanBlue),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loading ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: oceanBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isRegistering ? 'Create Account' : 'Login'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            setState(() {
                              isRegistering = !isRegistering;
                            });
                          },
                    child: Text(
                      isRegistering
                          ? 'Already have an account? Login'
                          : 'New to AquaLink? Create an account',
                      style: const TextStyle(color: oceanBlue),
                    ),
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

// ADMIN DASHBOARD
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> assignAgent(
    String reportId,
    String agentUid,
    String agentName,
  ) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update(
      {
        'assignedAgentUid': agentUid,
        'assignedAgentName': agentName,
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'Assigned',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('reports').snapshots(),
        builder: (context, reportSnapshot) {
          if (reportSnapshot.hasError) {
            return const Center(child: Text('Could not load reports.'));
          }

          if (!reportSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = reportSnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'agent')
                .snapshots(),
            builder: (context, agentSnapshot) {
              if (agentSnapshot.hasError) {
                return const Center(
                  child: Text('Could not load water agents.'),
                );
              }

              if (!agentSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final agents = agentSnapshot.data!.docs;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Total reports: ${reports.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (agents.isEmpty)
                    const Text(
                      'No water agents registered yet. '
                      'Agent accounts must be created and authorised first.',
                    ),
                  ...reports.map((document) {
                    final report = document.data();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report['category'] ?? 'Water Problem',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Reference: ${report['referenceNumber'] ?? 'N/A'}',
                            ),
                            Text(
                              'Location: ${report['location'] ?? 'Not provided'}',
                            ),
                            Text('Status: ${report['status'] ?? 'Submitted'}'),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  agents.any(
                                    (agent) =>
                                        agent.id == report['assignedAgentUid'],
                                  )
                                  ? report['assignedAgentUid'] as String
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Assign water agent',
                                border: OutlineInputBorder(),
                              ),
                              items: agents.map((agent) {
                                final data = agent.data();
                                return DropdownMenuItem<String>(
                                  value: agent.id,
                                  child: Text(
                                    data['fullName'] ??
                                        data['email'] ??
                                        'Agent',
                                  ),
                                );
                              }).toList(),
                              onChanged: (agentUid) async {
                                if (agentUid == null) return;

                                final selectedAgent = agents.firstWhere(
                                  (agent) => agent.id == agentUid,
                                );

                                final data = selectedAgent.data();

                                await assignAgent(
                                  document.id,
                                  agentUid,
                                  data['fullName'] ?? data['email'] ?? 'Agent',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// WATER AGENT DASHBOARD
class AgentDashboard extends StatelessWidget {
  const AgentDashboard({super.key});

  Future<void> updateStatus(String reportId, String status) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update(
      {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Agent Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('assignedAgentUid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load assigned reports.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          if (reports.isEmpty) {
            return const Center(
              child: Text('You have no assigned reports yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final document = reports[index];
              final report = document.data();

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['category'] ?? 'Water Problem',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Reference: ${report['referenceNumber'] ?? 'N/A'}'),
                      Text('Description: ${report['description'] ?? ''}'),
                      Text('Location: ${report['location'] ?? 'Not provided'}'),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue:
                            [
                              'Assigned',
                              'In Progress',
                              'Resolved',
                            ].contains(report['status'])
                            ? report['status'] as String
                            : 'Assigned',
                        decoration: const InputDecoration(
                          labelText: 'Update report status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Assigned',
                            child: Text('Assigned'),
                          ),
                          DropdownMenuItem(
                            value: 'In Progress',
                            child: Text('In Progress'),
                          ),
                          DropdownMenuItem(
                            value: 'Resolved',
                            child: Text('Resolved'),
                          ),
                        ],
                        onChanged: (status) {
                          if (status != null) {
                            updateStatus(document.id, status);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
