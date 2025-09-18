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
import 'package:provider/provider.dart';
import 'Admin.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class MyAdmins extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Admin Dashboard',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: appState.themeMode,
          home: AuthWrapper(),
          routes: {
            '/login': (context) => AdminLoginPage(),
            '/signup': (context) => AdminSignUpPage(),
            '/admin': (context) => AdminDashboardPage(),
          },
        );
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
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 36),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.admin_panel_settings,
                                  size: 56, color: Color(0xFF43e97b)),
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
                                  prefixIcon: Icon(Icons.email,
                                      color: Color(0xFF43e97b)),
                                ),
                                validator: (val) =>
                                    val!.isEmpty ? 'Enter an email' : null,
                                onChanged: (val) {
                                  setState(() => email = val);
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock,
                                      color: Color(0xFF43e97b)),
                                ),
                                obscureText: true,
                                validator: (val) => val!.length < 6
                                    ? 'Enter a password 6+ chars long'
                                    : null,
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
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500),
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
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 36),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_add,
                                  size: 56, color: Color(0xFF43e97b)),
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
                                  prefixIcon: Icon(Icons.email,
                                      color: Color(0xFF43e97b)),
                                ),
                                validator: (val) =>
                                    val!.isEmpty ? 'Enter an email' : null,
                                onChanged: (val) {
                                  setState(() => email = val);
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock,
                                      color: Color(0xFF43e97b)),
                                ),
                                obscureText: true,
                                validator: (val) => val!.length < 6
                                    ? 'Enter a password 6+ chars long'
                                    : null,
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
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500),
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

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<int> _getNonAdminUserCount() async {
    QuerySnapshot totalSnapshot =
        await FirebaseFirestore.instance.collection('users').get();
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

  Future<int> _getApprovedReportsCount() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Approved')
        .where('admin_UID', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get();
    return snapshot.size;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.greenAccent : Colors.green,
        elevation: 2,
        shadowColor: Colors.green.withOpacity(0.3),
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: isDark ? Colors.black : Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () async {
              await appState.toggleTheme();
            },
          ),
          IconButton(
            icon:
                Icon(Icons.logout, color: isDark ? Colors.black : Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            color: theme.scaffoldBackgroundColor,
          ),
          // Animated background elements
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Floating circle 1
                  Positioned(
                    top: 150 + (_floatingController.value * 20),
                    left: 50 + (_floatingController.value * 30),
                    child: Opacity(
                      opacity: isDark ? 0.05 : 0.1,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? Colors.greenAccent : Colors.green[300],
                        ),
                      ),
                    ),
                  ),
                  // Floating circle 2
                  Positioned(
                    top: 300 + (_floatingController.value * -25),
                    right: 30 + (_floatingController.value * 20),
                    child: Opacity(
                      opacity: isDark ? 0.04 : 0.08,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.greenAccent : Colors.teal[200],
                        ),
                      ),
                    ),
                  ),
                  // Floating circle 3
                  Positioned(
                    bottom: 200 + (_floatingController.value * 15),
                    left: 20 + (_floatingController.value * -10),
                    child: Opacity(
                      opacity: isDark ? 0.03 : 0.06,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? Colors.greenAccent : Colors.green[400],
                        ),
                      ),
                    ),
                  ),
                  // Floating rectangle
                  Positioned(
                    top: 500 + (_floatingController.value * 10),
                    right: 100 + (_floatingController.value * -15),
                    child: Opacity(
                      opacity: isDark ? 0.025 : 0.05,
                      child: Transform.rotate(
                        angle: _floatingController.value * 0.2,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color:
                                isDark ? Colors.greenAccent : Colors.green[500],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Main content with fade and scale animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.greenAccent.withOpacity(0.1)
                              : Colors.green[50],
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isDark ? Colors.greenAccent : Colors.green)
                                      .withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Icon(
                          Icons.eco,
                          size: 100,
                          color: isDark
                              ? Colors.greenAccent
                              : const Color(0xFF43e97b),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: Text(
                          'Welcome Garbage Collectors!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.greenAccent
                                : const Color(0xFF43e97b),
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: isDark ? Colors.black54 : Colors.black12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Let\'s nurture our green planet.',
                        style: TextStyle(
                          fontSize: 20,
                          color:
                              theme.textTheme.bodyLarge?.color ?? Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 50),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            FutureBuilder<int>(
                              future: _getNotApprovedReportsCount(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
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
                                          builder: (context) =>
                                              const ReportScreen(),
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
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
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
                            FutureBuilder<int>(
                              future: _getApprovedReportsCount(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return DashboardCard(
                                    title: 'Approved',
                                    icon: Icons.star,
                                    value: '...',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PointPage()),
                                      );
                                    },
                                  );
                                } else if (snapshot.hasError) {
                                  return DashboardCard(
                                    title: 'Approved',
                                    icon: Icons.star,
                                    value: 'Err',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PointPage()),
                                      );
                                    },
                                  );
                                } else {
                                  return DashboardCard(
                                    title: 'Approved',
                                    icon: Icons.star,
                                    value: snapshot.data.toString(),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const PointPage()),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PointPage extends StatefulWidget {
  const PointPage({Key? key}) : super(key: key);

  @override
  _PointPageState createState() => _PointPageState();
}

class _PointPageState extends State<PointPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

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
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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

  // Helper method to build info chips
  Widget _buildInfoChip(IconData icon, String text, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.5 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? color.withOpacity(0.9) : color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? color.withOpacity(0.9) : color.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Query approvedReportsQuery = FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Approved')
        .where('admin_UID', isEqualTo: FirebaseAuth.instance.currentUser!.uid);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.greenAccent : Colors.green,
        elevation: 2,
        shadowColor: Colors.green.withOpacity(0.3),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.black : Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Approved Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: isDark ? Colors.black : Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            color: theme.scaffoldBackgroundColor,
          ),
          // Animated background elements
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Floating circle 1
                  Positioned(
                    top: 150 + (_floatingController.value * 20),
                    left: 50 + (_floatingController.value * 30),
                    child: Opacity(
                      opacity: isDark ? 0.05 : 0.1,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? Colors.greenAccent : Colors.green[300],
                        ),
                      ),
                    ),
                  ),
                  // Floating circle 2
                  Positioned(
                    top: 300 + (_floatingController.value * -25),
                    right: 30 + (_floatingController.value * 20),
                    child: Opacity(
                      opacity: isDark ? 0.04 : 0.08,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.greenAccent : Colors.teal[200],
                        ),
                      ),
                    ),
                  ),
                  // Floating circle 3
                  Positioned(
                    bottom: 200 + (_floatingController.value * 15),
                    left: 20 + (_floatingController.value * -10),
                    child: Opacity(
                      opacity: isDark ? 0.03 : 0.06,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? Colors.greenAccent : Colors.green[400],
                        ),
                      ),
                    ),
                  ),
                  // Floating rectangle
                  Positioned(
                    top: 500 + (_floatingController.value * 10),
                    right: 100 + (_floatingController.value * -15),
                    child: Opacity(
                      opacity: isDark ? 0.025 : 0.05,
                      child: Transform.rotate(
                        angle: _floatingController.value * 0.2,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color:
                                isDark ? Colors.greenAccent : Colors.green[500],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Main content with fade and scale animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: StreamBuilder<QuerySnapshot>(
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
                    return Center(
                      child: CircularProgressIndicator(
                        color: isDark
                            ? Colors.greenAccent
                            : const Color(0xFF43e97b),
                      ),
                    );
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.greenAccent.withOpacity(0.1)
                                  : Colors.green[50],
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                          ? Colors.greenAccent
                                          : Colors.green)
                                      .withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Icon(
                              Icons.check_circle_outline,
                              size: 80,
                              color: isDark
                                  ? Colors.greenAccent
                                  : const Color(0xFF43e97b),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No approved reports found.',
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.textTheme.bodyLarge?.color ??
                                  Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
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
                      double reportLat = (data['latitude'] is num)
                          ? data['latitude'].toDouble()
                          : 0.0;
                      double reportLon = (data['longitude'] is num)
                          ? data['longitude'].toDouble()
                          : 0.0;
                      int reportPoints = data['Points'] ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(
                                  0xFF2A2A2A) // Light black for dark theme
                              : Colors.white, // White for light theme
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isDark ? Colors.greenAccent : Colors.green)
                                      .withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row with Image and Status
                              Row(
                                children: [
                                  // Report Image
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isDark
                                                  ? Colors.greenAccent
                                                  : Colors.green)
                                              .withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: imageBytes != null
                                          ? Image.memory(
                                              imageBytes,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.greenAccent
                                                        .withOpacity(0.1)
                                                    : Colors.green[50],
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Icon(
                                                Icons.image,
                                                color: isDark
                                                    ? Colors.greenAccent
                                                    : const Color(0xFF43e97b),
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Content Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Status Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                isDark
                                                    ? Colors.greenAccent
                                                        .withOpacity(0.2)
                                                    : Colors.green[100]!,
                                                isDark
                                                    ? Colors.greenAccent
                                                        .withOpacity(0.1)
                                                    : Colors.green[50]!,
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.greenAccent
                                                  : const Color(0xFF43e97b),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: isDark
                                                    ? Colors.greenAccent
                                                    : Colors.green[600],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Approved',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.greenAccent
                                                      : Colors.green[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Points Display
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: (isDark
                                                    ? Colors.greenAccent
                                                    : const Color(0xFF43e97b))
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '+$reportPoints Points',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.greenAccent
                                                  : const Color(0xFF43e97b),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Report Title
                              Text(
                                data['complaintText'] ?? 'No Complaint',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.textTheme.titleLarge?.color ??
                                      (isDark
                                          ? Colors.white
                                          : const Color(0xFF2E3A45)),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              // Report Details Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoChip(
                                      Icons.calendar_today,
                                      formattedDate,
                                      Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(reportUserId)
                                          .get(),
                                      builder: (context, userSnapshot) {
                                        String userName = 'Loading...';
                                        if (userSnapshot.hasData &&
                                            userSnapshot.data!.exists) {
                                          final userData = userSnapshot.data!
                                              .data() as Map<String, dynamic>;
                                          userName =
                                              userData['name'] ?? 'Unknown';
                                        } else if (userSnapshot.hasError ||
                                            !userSnapshot.hasData) {
                                          userName = 'Unknown';
                                        }
                                        return _buildInfoChip(
                                          Icons.person,
                                          userName,
                                          Colors.orange,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [Colors.greenAccent, Colors.teal]
                                          : [
                                              const Color(0xFF43e97b),
                                              const Color(0xFF38d9a9)
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isDark
                                                ? Colors.greenAccent
                                                : Colors.green)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        // Get current user's location using Geolocator.
                                        Position position =
                                            await _getCurrentPosition();
                                        double userLat = position.latitude;
                                        double userLon = position.longitude;

                                        // Calculate the distance between the report's location and the user's current location.
                                        double distance = calculateDistance(
                                            reportLat,
                                            reportLon,
                                            userLat,
                                            userLon);
                                        // Define a threshold distance in kilometers.
                                        const double thresholdDistance = 1.0;

                                        if (distance <= thresholdDistance) {
                                          // User is close enough; update their totalScore.
                                          String currentUserId = FirebaseAuth
                                              .instance.currentUser!.uid;
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(reportUserId)
                                              .update({
                                            'totalScore': FieldValue.increment(
                                                reportPoints),
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
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "Collection successful! Points added to your total score."),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } else {
                                          // User is too far away.
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  "You are not close enough to collect this product."),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text("Error: $e"),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                    ),
                                    icon:
                                        const Icon(Icons.check_circle_outline),
                                    label: const Text(
                                      'Collect Report',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2A2A2A) // Light black for dark theme
              : Colors.grey[50], // Very light gray for light theme
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.greenAccent.withOpacity(0.3)
                : Colors.green[100]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isDark ? Colors.greenAccent : Colors.green).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.greenAccent.withOpacity(0.1)
                    : Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: isDark ? Colors.greenAccent : const Color(0xFF43e97b),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.greenAccent : const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color ?? Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Query reportsQuery = FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Not Approved');

    Future<String> getAddressFromLatLng(
        double latitude, double longitude) async {
      try {
        List<Placemark> placemarks =
            await placemarkFromCoordinates(latitude, longitude);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.greenAccent : Colors.green,
        elevation: 2,
        shadowColor: Colors.green.withOpacity(0.3),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.black : Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reports',
          style: TextStyle(
            color: isDark ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.black : Colors.white),
      ),
      body: Stack(
        children: [
          // Background
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          // Animated background elements
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;

              return Stack(
                children: [
                  // Floating circle 1
                  Positioned(
                    top: 100 + (_floatingController.value * 15),
                    left: 30 + (_floatingController.value * 25),
                    child: Opacity(
                      opacity: isDark ? 0.04 : 0.08,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? Colors.greenAccent : Colors.green[300],
                        ),
                      ),
                    ),
                  ),
                  // Floating circle 2
                  Positioned(
                    top: 250 + (_floatingController.value * -20),
                    right: 40 + (_floatingController.value * 15),
                    child: Opacity(
                      opacity: isDark ? 0.03 : 0.06,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.greenAccent : Colors.teal[200],
                        ),
                      ),
                    ),
                  ),
                  // Floating circle 3
                  Positioned(
                    bottom: 150 + (_floatingController.value * 12),
                    left: 15 + (_floatingController.value * -8),
                    child: Opacity(
                      opacity: isDark ? 0.025 : 0.05,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? Colors.greenAccent : Colors.green[400],
                        ),
                      ),
                    ),
                  ),
                  // Additional floating rectangle
                  Positioned(
                    top: 400 + (_floatingController.value * 8),
                    right: 20 + (_floatingController.value * -12),
                    child: Opacity(
                      opacity: isDark ? 0.02 : 0.04,
                      child: Transform.rotate(
                        angle: _floatingController.value * 0.3,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color:
                                isDark ? Colors.greenAccent : Colors.green[500],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Small floating circle
                  Positioned(
                    top: 180 + (_floatingController.value * -10),
                    left: 200 + (_floatingController.value * 20),
                    child: Opacity(
                      opacity: isDark ? 0.035 : 0.07,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.greenAccent : Colors.teal[300],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Main content with animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: StreamBuilder<QuerySnapshot>(
                stream: reportsQuery.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red[600]),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.greenAccent
                            : const Color(0xFF43e97b),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    final theme = Theme.of(context);
                    final isDark = theme.brightness == Brightness.dark;

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.report_off,
                            size: 80,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reports found.',
                            style: TextStyle(
                              fontSize: 18,
                              color: theme.textTheme.bodyLarge?.color ??
                                  (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
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
                      final double latitude =
                          (data['latitude'] ?? 0).toDouble();
                      final double longitude =
                          (data['longitude'] ?? 0).toDouble();
                      return GestureDetector(
                        onTap: () async {
                          String address =
                              await getAddressFromLatLng(latitude, longitude);
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
                                latitude: latitude,
                                longitude: longitude,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          margin: const EdgeInsets.only(bottom: 16),
                          shadowColor:
                              (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.greenAccent
                                      : Colors.green)
                                  .withOpacity(0.3),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(
                                  0xFF2A2A2A) // Light black for dark theme
                              : Colors.white, // White for light theme
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.greenAccent
                                                .withOpacity(0.1)
                                            : Colors.green[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.report,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.greenAccent
                                            : const Color(0xFF43e97b),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        complaintText,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.color ??
                                              (Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : const Color(0xFF2E7D32)),
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Wrap in Flexible to prevent overflow
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildInfoChip('Qty: $quantity',
                                        Icons.confirmation_num),
                                    _buildInfoChip(
                                        'Wt: ${weightPerKg.toStringAsFixed(1)} Kg',
                                        Icons.fitness_center),
                                    _buildInfoChip('Date: $formattedDate',
                                        Icons.calendar_today),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Flexible container for category to prevent overflow
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.greenAccent.withOpacity(0.1)
                                        : Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.greenAccent.withOpacity(0.3)
                                          : Colors.green[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.category,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.greenAccent
                                            : const Color(0xFF43e97b),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Category: $category',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.greenAccent
                                                        .withOpacity(0.9)
                                                    : const Color(0xFF2E7D32),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color:
              isDark ? Colors.greenAccent.withOpacity(0.1) : Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? Colors.greenAccent.withOpacity(0.3)
                : Colors.green[200]!,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: isDark ? Colors.greenAccent : const Color(0xFF43e97b)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.greenAccent.withOpacity(0.9)
                      : const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
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

class _ReportDetailScreenState extends State<ReportDetailScreen>
    with TickerProviderStateMixin {
  String address = 'Fetching address...';
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fetchAddress();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
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
    bool isNonBio =
        nonBioKeywords.any((keyword) => lowerCategory.contains(keyword));
    int basePoints = isNonBio ? 5 : 10;
    return (basePoints * weight).round();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Uint8List? imageBytes;
    if (widget.imageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(widget.imageBase64);
      } catch (e) {
        imageBytes = null;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.greenAccent : Colors.green,
        elevation: 2,
        shadowColor: Colors.green.withOpacity(0.3),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.black : Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Theme-aware background
          Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF121212)
                : Colors.white,
          ),
          // Animated background elements
          AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Stack(
                children: [
                  // Floating circle 1
                  Positioned(
                    top: 80 + (_floatingController.value * 12),
                    left: 25 + (_floatingController.value * 20),
                    child: Opacity(
                      opacity: isDark ? 0.03 : 0.06,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? Colors.greenAccent : Colors.green[300],
                        ),
                      ),
                    ),
                  ),
                  // Floating circle 2
                  Positioned(
                    top: 200 + (_floatingController.value * -15),
                    right: 30 + (_floatingController.value * 12),
                    child: Opacity(
                      opacity: isDark ? 0.025 : 0.05,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.greenAccent.withOpacity(0.7)
                              : Colors.teal[200],
                        ),
                      ),
                    ),
                  ),
                  // Floating circle 3
                  Positioned(
                    bottom: 120 + (_floatingController.value * 10),
                    left: 40 + (_floatingController.value * -8),
                    child: Opacity(
                      opacity: isDark ? 0.02 : 0.04,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? Colors.greenAccent : Colors.green[400],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Main content with animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Main detail card
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        shadowColor: Colors.green.withOpacity(0.2),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(
                                0xFF2A2A2A) // Light black for dark theme
                            : Colors.white, // White for light theme
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image section
                              if (imageBytes != null)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.greenAccent.withOpacity(0.5)
                                          : Colors.green[200]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.memory(
                                      imageBytes,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 220,
                                    ),
                                  ),
                                ),
                              if (imageBytes != null)
                                const SizedBox(height: 20),

                              // Details section
                              _buildDetailCard(
                                  'Location', address, Icons.location_on),
                              const SizedBox(height: 12),
                              _buildDetailCard(
                                  'Category', widget.category, Icons.category),
                              const SizedBox(height: 12),
                              _buildDetailCard('Complaint',
                                  widget.complaintText, Icons.report_problem),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDetailCard(
                                        'Quantity',
                                        widget.quantity.toString(),
                                        Icons.confirmation_num),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDetailCard(
                                        'Weight',
                                        '${widget.weightPerKg} Kg',
                                        Icons.fitness_center),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildDetailCard(
                                  'Date', widget.date, Icons.calendar_today),
                              const SizedBox(height: 12),
                              _buildStatusCard(widget.status),
                              const SizedBox(height: 12),

                              // User information
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.userId)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.green[200]!),
                                      ),
                                      child: const Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF43e97b),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text("Loading user information..."),
                                        ],
                                      ),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return _buildDetailCard('Reported by',
                                        'Unknown user', Icons.person);
                                  }
                                  final userData = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  String userName =
                                      userData['name'] ?? "Unknown";
                                  String phone =
                                      userData['phone'] ?? "Not available";

                                  return Column(
                                    children: [
                                      _buildDetailCard('Reported by', userName,
                                          Icons.person),
                                      const SizedBox(height: 12),
                                      _buildDetailCard(
                                          'Contact', phone, Icons.phone),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Approve button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF43e97b),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 4,
                            shadowColor: Colors.green.withOpacity(0.3),
                          ),
                          onPressed: () async {
                            int points = computePoints(
                                widget.category, widget.weightPerKg);
                            try {
                              // Get current admin's UID
                              String currentAdminUID =
                                  FirebaseAuth.instance.currentUser!.uid;

                              await FirebaseFirestore.instance
                                  .collection('reports')
                                  .doc(widget.reportId)
                                  .update({
                                'status': 'Approved',
                                'CleanedBy': currentAdminUID,
                                'Points': points,
                                'admin_UID':
                                    currentAdminUID, // Store admin's UID
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Report approved successfully!'),
                                  backgroundColor: Color(0xFF43e97b),
                                ),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error approving report: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Approve Report',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to create a detail card
  Widget _buildDetailCard(String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.greenAccent.withOpacity(0.1) : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isDark ? Colors.greenAccent.withOpacity(0.3) : Colors.green[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.greenAccent : const Color(0xFF43e97b),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.black : Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDark ? Colors.greenAccent : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to create a status card
  Widget _buildStatusCard(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'not approved':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              statusIcon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 16,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to create a detail row (kept for compatibility)
  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }
}
