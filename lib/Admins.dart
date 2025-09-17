import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'Admin.dart';


class MyAdmins extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Collectors!!',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF43e97b),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.85),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: const TextStyle(color: Color(0xFF43e97b)),
        ),
      ),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => AdminLoginPage(),
        '/signup': (context) => AdminSignUpPage(),
        '/admin': (context) => AdminDashboardPage(),
      },
    );
  }
}

/// AuthWrapper checks the login state using FirebaseAuth.
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If connection is active, decide which page to show.
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          return user == null ? AdminLoginPage() : AdminDashboardPage();
        }
        // Loading state while waiting for authentication info.
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;
  String error = '';

  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);

      // ✅ Bypass Firebase Auth for ragavi@gmail.com
      if (email == "ragavi@gmail.com" && password == "1234567890") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminPage()),
        );
        setState(() => loading = false);
        return;
      }

      try {
        // ✅ Sign in the user with Firebase Authentication
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // ✅ Verify that the user's document exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (!userDoc.exists) {
          setState(() {
            error = "User record not found. Please sign up first.";
            loading = false;
          });
          await FirebaseAuth.instance.signOut();
          return;
        }

        // ✅ On success, AuthWrapper (or similar logic) will handle navigation
      } catch (e) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Glassmorphic login card
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.admin_panel_settings, size: 56, color: Color(0xFF43e97b)),
                              const SizedBox(height: 18),
                              Text(
                                'Welcome Garbage Collectors',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                  letterSpacing: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email, color: Color(0xFF43e97b)),
                                ),
                                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                                onChanged: (val) {
                                  setState(() => email = val);
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock, color: Color(0xFF43e97b)),
                                ),
                                obscureText: true,
                                validator: (val) => val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                                onChanged: (val) {
                                  setState(() => password = val);
                                },
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: login,
                                  child: const Text('Login'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedOpacity(
                                opacity: error.isNotEmpty ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  error,
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/signup');
                                },
                                child: Text(
                                  'Don\'t have an account? Sign Up',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green[800],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (loading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF43e97b)),
              ),
            ),
        ],
      ),
    );
  }
}
/// Admin Sign Up Page
class AdminSignUpPage extends StatefulWidget {
  @override
  _AdminSignUpPageState createState() => _AdminSignUpPageState();
}

class _AdminSignUpPageState extends State<AdminSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool loading = false;
  String error = '';

  Future<void> signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      try {
        // Create user via Firebase Authentication.
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Store the new user's information into the "users" collection.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'admin',
        });
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_add, size: 56, color: Color(0xFF43e97b)),
                              const SizedBox(height: 18),
                              Text(
                                'Create Admin Account',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                  letterSpacing: 1.1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email, color: Color(0xFF43e97b)),
                                ),
                                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                                onChanged: (val) {
                                  setState(() => email = val);
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock, color: Color(0xFF43e97b)),
                                ),
                                obscureText: true,
                                validator: (val) => val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                                onChanged: (val) {
                                  setState(() => password = val);
                                },
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: signUp,
                                  child: const Text('Sign Up'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedOpacity(
                                opacity: error.isNotEmpty ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  error,
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Already have an account? Log in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.green[800],
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (loading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF43e97b)),
              ),
            ),
        ],
      ),
    );
  }
}


class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  Future<int> _getNonAdminUserCount() async {
    QuerySnapshot totalSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();
    int totalCount = totalSnapshot.size;

    QuerySnapshot adminSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    int adminCount = adminSnapshot.size;

    return totalCount - adminCount;
  }

  Future<int> _getNotApprovedReportsCount() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Not Approved')
        .get();
    return snapshot.size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: Colors.black26,
                offset: Offset(1, 2),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.eco,
                      size: 100,
                      color: Color(0xFF43e97b),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Welcome Garbage Collectors!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF43e97b),
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Let\'s nurture our green planet.',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      FutureBuilder<int>(
                        future: _getNotApprovedReportsCount(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return DashboardCard(
                              title: 'Reports',
                              icon: Icons.report,
                              value: '...',
                            );
                          } else if (snapshot.hasError) {
                            return DashboardCard(
                              title: 'Reports',
                              icon: Icons.report,
                              value: 'Err',
                            );
                          } else {
                            return DashboardCard(
                              title: 'Reports',
                              icon: Icons.report,
                              value: snapshot.data.toString(),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ReportScreen(),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                      FutureBuilder<int>(
                        future: _getNonAdminUserCount(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return DashboardCard(
                              title: 'Users',
                              icon: Icons.people,
                              value: '...',
                            );
                          } else if (snapshot.hasError) {
                            return DashboardCard(
                              title: 'Users',
                              icon: Icons.people,
                              value: 'Err',
                            );
                          } else {
                            return DashboardCard(
                              title: 'Users',
                              icon: Icons.people,
                              value: snapshot.data.toString(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DashboardCard(
                    title: 'Points',
                    icon: Icons.stars,
                    value: '',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PointPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class PointPage extends StatelessWidget {
  const PointPage({Key? key}) : super(key: key);

  // Format the date string.
  String _formatDate(String dateStr) {
    if (dateStr.isNotEmpty) {
      try {
        DateTime dt = DateTime.parse(dateStr);
        return DateFormat('dd MMM yyyy').format(dt);
      } catch (e) {
        return dateStr;
      }
    }
    return 'No Date';
  }

  // Calculate distance in kilometers using the Haversine formula.
  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radius of Earth in km.
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  // Function to get the current user's position using Geolocator.
  Future<Position> _getCurrentPosition() async {
    // Check permission status first.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw Exception('Location permissions are denied');
      }
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    Query approvedReportsQuery = FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Approved')
        .where('CleanedBy',isEqualTo: FirebaseAuth.instance.currentUser!.uid);

    return Stack(
      children: [
        // Full-screen background image with white fading overlay.
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: const AssetImage('lib/assets/ease.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.3),
                BlendMode.dstATop,
              ),
            ),
          ),
        ),
        Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(
              'Approved Reports',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 8.0,
                    color: Colors.black26,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            elevation: 4,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: approvedReportsQuery.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No approved reports found.',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 20, 16, 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  String imageBase64 = data['image'] ?? '';
                  String reportId = docs[index].id;
                  Uint8List? imageBytes;
                  if (imageBase64.isNotEmpty) {
                    try {
                      imageBytes = base64Decode(imageBase64);
                    } catch (e) {
                      imageBytes = null;
                    }
                  }
                  String dateStr = data['date'] ?? '';
                  String formattedDate = _formatDate(dateStr);
                  String reportUserId = data['userId'] ?? '';
                  // Assuming report document has numeric fields for latitude and longitude.
                  double reportLat =
                  (data['latitude'] is num) ? data['latitude'].toDouble() : 0.0;
                  double reportLon =
                  (data['longitude'] is num) ? data['longitude'].toDouble() : 0.0;
                  int reportPoints = data['Points'] ?? 0;

                  return Card(
                    elevation: 6,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      leading: imageBytes != null
                          ? CircleAvatar(
                        radius: 30,
                        backgroundImage: MemoryImage(imageBytes),
                      )
                          : const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.image, color: Colors.white),
                        backgroundColor: Colors.grey,
                      ),
                      title: Text(
                        data['complaintText'] ?? 'No Complaint',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Date: $formattedDate',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(reportUserId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text(
                                  'Reported by: Loading...',
                                  style: TextStyle(fontSize: 14),
                                );
                              }
                              if (userSnapshot.hasError ||
                                  !userSnapshot.hasData ||
                                  !userSnapshot.data!.exists) {
                                return const Text(
                                  'Reported by: Unknown',
                                  style: TextStyle(fontSize: 14),
                                );
                              }
                              final userData = userSnapshot.data!.data()
                              as Map<String, dynamic>;
                              String userName =
                                  userData['name'] ?? 'Unknown';
                              return Text(
                                'Reported by: $userName',
                                style: const TextStyle(fontSize: 14),
                              );
                            },
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            // Get current user's location using Geolocator.
                            Position position = await _getCurrentPosition();
                            double userLat = position.latitude;
                            double userLon = position.longitude;

                            // Calculate the distance between the report's location and the user's current location.
                            double distance = calculateDistance(
                                reportLat, reportLon, userLat, userLon);
                            // Define a threshold distance in kilometers.
                            const double thresholdDistance = 1.0;

                            if (distance <= thresholdDistance) {
                              // User is close enough; update their totalScore.
                              String currentUserId =
                                  FirebaseAuth.instance.currentUser!.uid;
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(reportUserId)
                                  .update({
                                'totalScore': FieldValue.increment(reportPoints),
                              });
                              await FirebaseFirestore.instance
                                  .collection('reports')
                                  .doc(reportId)
                                  .update({
                                'status': 'Ok',
                              });
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUserId)
                                  .update({
                                'scores': FieldValue.increment(5),
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Collection successful! Points added to your total score."),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              // User is too far away.
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "You are not close enough to collect this product."),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Collect',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final VoidCallback? onTap; // Add onTap parameter

  const DashboardCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.value,
    this.onTap, // Handle onTap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Handle tap
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 160,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 44,
                  color: const Color(0xFF43e97b),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Query reportsQuery = FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Not Approved');

    Future<String> getAddressFromLatLng(double latitude, double longitude) async {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          return "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        }
      } catch (e) {
        print("Error fetching address: $e");
        return "Unknown address";
      }
      return "Unknown address";
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports',style: TextStyle(color:Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green,
      ),
      // Background container with image and white fading overlay.
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('lib/assets/ease.jpg'),
            fit: BoxFit.cover,
            // Apply a white fading overlay.
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.3),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: reportsQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('No reports found.'));
            }

            return ListView.builder(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data =
                docs[index].data() as Map<String, dynamic>;
                String complaintText = data['complaintText'] ?? '';
                String? dateStr = data['date'];
                String formattedDate;
                if (dateStr != null && dateStr.isNotEmpty) {
                  try {
                    DateTime parsedDate = DateTime.parse(dateStr);
                    formattedDate =
                        DateFormat('dd-MM-yyyy').format(parsedDate);
                  } catch (e) {
                    formattedDate = 'Invalid Date';
                  }
                } else {
                  formattedDate = 'No Date';
                }
                int quantity = data['quantity'] ?? 0;
                double weightPerKg = (data['weightPerKg'] is int)
                    ? (data['weightPerKg'] as int).toDouble()
                    : (data['weightPerKg'] ?? 0.0);
                String category = data['category'] ?? '';
                final double latitude = (data['latitude'] ?? 0).toDouble();
                final double longitude = (data['longitude'] ?? 0).toDouble();
                return GestureDetector(
                  onTap: () async {
                    String address = await getAddressFromLatLng(latitude, longitude);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportDetailScreen(
                          reportId: docs[index].id,
                          complaintText: complaintText,
                          date: formattedDate,
                          quantity: quantity,
                          weightPerKg: weightPerKg,
                          status: data['status'] ?? '',
                          userId: data['userId'] ?? '',
                          imageBase64: data['image'] ?? '',
                          category: category,
                          latitude : latitude,
                          longitude : longitude,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    margin: const EdgeInsets.only(bottom: 16),
                    shadowColor: Colors.green.withOpacity(0.6),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.report,
                                  color: Colors.green, size: 28),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  complaintText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Use a row to space out the info chips.
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              _buildInfoChip(
                                  'Qty: $quantity',
                                  Icons.confirmation_num),
                              _buildInfoChip(
                                  'Wt: ${weightPerKg.toStringAsFixed(1)} Kg',
                                  Icons.fitness_center),
                              _buildInfoChip('Date: $formattedDate',
                                  Icons.calendar_today),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Category: $category',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.green.shade700),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }
}

class ReportDetailScreen extends StatefulWidget {
  final String reportId;
  final String complaintText;
  final String date;
  final int quantity;
  final double weightPerKg;
  final String status;
  final String userId;
  final String imageBase64;
  final String category;
  final double latitude;
  final double longitude;

  const ReportDetailScreen({
    Key? key,
    required this.reportId,
    required this.complaintText,
    required this.date,
    required this.quantity,
    required this.weightPerKg,
    required this.status,
    required this.userId,
    required this.imageBase64,
    required this.category,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _ReportDetailScreenState createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  String address = 'Fetching address...';

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  // Function to fetch the address from RapidAPI using latitude and longitude
  Future<void> _fetchAddress() async {
    const String apiKey = 'd51e83b273mshc84732abf348ebap1177c2jsne187797f8c50';
    const String apiHost = 'address-from-to-latitude-longitude.p.rapidapi.com';

    final url = Uri.parse(
        'https://$apiHost/geolocationapi?lat=${widget.latitude}&lng=${widget.longitude}');

    try {
      final response = await http.get(
        url,
        headers: {
          'x-rapidapi-key': apiKey,
          'x-rapidapi-host': apiHost,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Results'] != null && data['Results'].isNotEmpty) {
          final result = data['Results'][0];
          setState(() {
            address = result['address'] ?? 'Address not found';
          });
        } else {
          setState(() {
            address = 'Address not found';
          });
        }
      } else {
        setState(() {
          address = 'Failed to fetch address: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error fetching address: $e'); // Debugging statement
      setState(() {
        address = 'Error: $e';
      });
    }
  }

  // Function to compute points based on category and weight
  int computePoints(String category, double weight) {
    final lowerCategory = category.toLowerCase();
    const nonBioKeywords = [
      'metal',
      'metals',
      'aluminium',
      'cans',
      'e-waste',
      'plastic',
      'plastics',
      'glass',
      'batteries',
      'electronics',
      'styrofoam',
      'rubber',
      'vinyl'
    ];
    bool isNonBio = nonBioKeywords.any((keyword) => lowerCategory.contains(keyword));
    int basePoints = isNonBio ? 5 : 10;
    return (basePoints * weight).round();
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (widget.imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(widget.imageBase64);
      } catch (e) {
        imageBytes = null;
      }
    }

    return Stack(
      children: [
        // Full-screen background image with gradient overlay and blur effect
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/ease.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Report Details',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 8.0,
                    color: Colors.black26,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            elevation: 4,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 24, 16, 16),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Display Address
                      _buildDetailRow('Address', address),
                      const SizedBox(height: 12),
                      _buildDetailRow('Category', widget.category),
                      const SizedBox(height: 12),
                      _buildDetailRow('Complaint', widget.complaintText),
                      const SizedBox(height: 12),
                      _buildDetailRow('Quantity', widget.quantity.toString()),
                      const SizedBox(height: 12),
                      _buildDetailRow('Weight per Kg', widget.weightPerKg.toString()),
                      const SizedBox(height: 12),
                      _buildDetailRow('Date', widget.date),
                      const SizedBox(height: 12),
                      _buildDetailRow('Status', widget.status),
                      const SizedBox(height: 12),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Row(
                              children: const [
                                CircularProgressIndicator(strokeWidth: 2),
                                SizedBox(width: 8),
                                Text("Loading user name..."),
                              ],
                            );
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text("Unknown user");
                          }
                          final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                          String userName = userData['name'] ?? "Unknown";
                          String phone  = userData['phone']??"9080262334";
                          return _buildDetailRow('Contact', phone);
                        },
                      ),
                      // Display User Name with a loading indicator
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Row(
                              children: const [
                                CircularProgressIndicator(strokeWidth: 2),
                                SizedBox(width: 8),
                                Text("Loading user name..."),
                              ],
                            );
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text("Unknown user");
                          }
                          final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                          String userName = userData['name'] ?? "Unknown";
                          String phone  = userData['phone']??"9080262334";
                          return _buildDetailRow('Reported by', userName);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: () async {
                int points = computePoints(widget.category, widget.weightPerKg);
                try {
                  await FirebaseFirestore.instance
                      .collection('reports')
                      .doc(widget.reportId)
                      .update({
                    'status': 'Approved',
                    'CleanedBy': FirebaseAuth.instance.currentUser!.uid,
                    'Points': points,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report approved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error approving report: $e')),
                  );
                }
              },
              child: const Text(
                'Approve',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper function to create a detail row
  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
