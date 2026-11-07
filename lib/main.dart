import 'package:flutter/material.dart';

const Color skyBlue = Color(0xFF79C9EA);
const Color iceBlue = Color(0xFFBDEBFA);
const Color cloudBlue = Color(0xFFEAF8FD);
const Color oceanBlue = Color(0xFF247B9E);
const Color navy = Color(0xFF173B50);

void main() {
  runApp(const AquaLinkApp());
}

class AquaLinkApp extends StatelessWidget {
  const AquaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cloudBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: oceanBlue,
          primary: oceanBlue,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: skyBlue,
          foregroundColor: navy,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: const Row(
          children: [
            AquaLinkLogo(size: 38),
            SizedBox(width: 10),
            Text('AquaLink', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () =>
                showMessage(context, 'Notifications will be available soon!'),
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
          ),
        ],
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
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Main reporting banner
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
                    style: TextStyle(color: navy, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () => showMessage(
                      context,
                      'The water reporting form is coming soon!',
                    ),
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

            const SizedBox(height: 30),

            const Text(
              'What would you like to report?',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
            const SizedBox(height: 15),

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

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.people_outline, color: oceanBlue, size: 34),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Together, we can help build communities '
                      'with safer and more reliable water services.',
                      style: TextStyle(color: navy, fontSize: 14, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          final messages = [
            'You are already on Home.',
            'The reporting page is coming soon!',
            'Your reports will appear here soon!',
          ];

          showMessage(context, messages[index]);
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
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
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
