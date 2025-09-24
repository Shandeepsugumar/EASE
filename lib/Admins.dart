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

      // âœ… Bypass Firebase Auth for ragavi@gmail.com
      if (email == "ragavi@gmail.com" && password == "1234567890") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminPage()),
        );
        setState(() => loading = false);
        return;
      }

      try {
        // âœ… Sign in the user with Firebase Authentication
        final credential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // âœ… Verify that the user's document exists in Firestore
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

        // âœ… On success, AuthWrapper (or similar logic) will handle navigation
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
                                style: const TextStyle(color: Colors.black),
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
                                style: const TextStyle(color: Colors.black),
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
                                style: const TextStyle(color: Colors.black),
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
                                style: const TextStyle(color: Colors.black),
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
  late AnimationController _heartbeatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _heartbeatAnimation;

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

    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _heartbeatAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _heartbeatController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    _heartbeatController.dispose();
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

  // Stream version for real-time updates
  Stream<int> _getNonAdminUserCountStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((snapshot) {
      int totalCount = snapshot.docs.length;
      int adminCount =
          snapshot.docs.where((doc) => doc.data()['role'] == 'admin').length;
      return totalCount - adminCount;
    });
  }

  Future<int> _getNotApprovedReportsCount() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Not Approved')
        .get();
    return snapshot.size;
  }

  // Stream version for real-time updates
  Stream<int> _getNotApprovedReportsCountStream() {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Not Approved')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<int> _getApprovedReportsCount() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user found for approved reports count');
        return 0;
      }

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'Approved')
          .where('Admin_UID', isEqualTo: currentUser.uid)
          .get();

      print(
          'Approved reports count for admin ${currentUser.uid}: ${snapshot.size}');
      return snapshot.size;
    } catch (e) {
      print('Error getting approved reports count: $e');
      return 0;
    }
  }

  // Stream for real-time approved reports count updates
  Stream<int> _getApprovedReportsCountStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Approved')
        .where('Admin_UID', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Stream for real-time sanitization reports count updates
  Stream<int> _getSanitizationReportsCountStream() {
    return FirebaseFirestore.instance
        .collection('sanitization')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  padding: const EdgeInsets.fromLTRB(24, 80, 24, 80),
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
                        child: AnimatedBuilder(
                          animation: _heartbeatAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _heartbeatAnimation.value,
                              child: Icon(
                                Icons.eco,
                                size: 100,
                                color: isDark
                                    ? Colors.greenAccent
                                    : const Color(0xFF43e97b),
                              ),
                            );
                          },
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
                            StreamBuilder<int>(
                              stream: _getNotApprovedReportsCountStream(),
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
                                    value: (snapshot.data ?? 0).toString(),
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
                            StreamBuilder<int>(
                              stream: _getNonAdminUserCountStream(),
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
                                    value: (snapshot.data ?? 0).toString(),
                                  );
                                }
                              },
                            ),
                            StreamBuilder<int>(
                              stream: _getApprovedReportsCountStream(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return DashboardCard(
                                    title: 'Approved',
                                    icon: Icons.verified,
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
                                    title: 'Approved Reports',
                                    icon: Icons.verified,
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
                                    icon: Icons.verified,
                                    value: (snapshot.data ?? 0).toString(),
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
                            StreamBuilder<int>(
                              stream: _getSanitizationReportsCountStream(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return DashboardCard(
                                    title: 'Sanitization',
                                    icon: Icons.cleaning_services,
                                    value: '...',
                                  );
                                } else if (snapshot.hasError) {
                                  return DashboardCard(
                                    title: 'Sanitization',
                                    icon: Icons.cleaning_services,
                                    value: 'Err',
                                  );
                                } else {
                                  return DashboardCard(
                                    title: 'Sanitization',
                                    icon: Icons.cleaning_services,
                                    value: (snapshot.data ?? 0).toString(),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SanitizationReportsScreen(),
                                        ),
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

  // Tab controller for switching between waste and sanitization reports
  int _selectedTabIndex = 0; // 0 for waste reports, 1 for sanitization reports

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

    // Get current user for filtering
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Approved Reports'),
        ),
        body: const Center(
          child: Text('Error: No authenticated user found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
              child: Column(
                children: [
                  // Tab buttons
                  Container(
                    margin: const EdgeInsets.fromLTRB(24, 100, 24, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 0;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: _selectedTabIndex == 0
                                    ? (isDark
                                        ? Colors.greenAccent
                                        : Colors.green)
                                    : Colors.transparent,
                              ),
                              child: Text(
                                'Waste Reports',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabIndex == 0
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark ? Colors.white : Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: _selectedTabIndex == 1
                                    ? (isDark
                                        ? Colors.greenAccent
                                        : Colors.green)
                                    : Colors.transparent,
                              ),
                              child: Text(
                                'Sanitization Reports',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabIndex == 1
                                      ? (isDark ? Colors.black : Colors.white)
                                      : (isDark ? Colors.white : Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Content based on selected tab
                  Expanded(
                    child: _selectedTabIndex == 0
                        ? _buildWasteReportsContent(
                            currentUser.uid, isDark, theme)
                        : _buildSanitizationReportsContent(
                            currentUser.uid, isDark, theme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build waste reports content
  Widget _buildWasteReportsContent(
      String adminUID, bool isDark, ThemeData theme) {
    Query approvedReportsQuery = FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Approved')
        .where('Admin_UID', isEqualTo: adminUID);

    return StreamBuilder<QuerySnapshot>(
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
              color: isDark ? Colors.greenAccent : const Color(0xFF43e97b),
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
                        color: (isDark ? Colors.greenAccent : Colors.green)
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
                    color:
                        isDark ? Colors.greenAccent : const Color(0xFF43e97b),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No approved waste reports found.',
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.textTheme.bodyLarge?.color ?? Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            String imageBase64 = data['image'] ?? '';
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
            int reportPoints = data['Points'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.greenAccent : Colors.green)
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
                                color:
                                    (isDark ? Colors.greenAccent : Colors.green)
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
                                          ? Colors.greenAccent.withOpacity(0.1)
                                          : Colors.green[50],
                                      borderRadius: BorderRadius.circular(15),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isDark
                                          ? Colors.greenAccent.withOpacity(0.2)
                                          : Colors.green[100]!,
                                      isDark
                                          ? Colors.greenAccent.withOpacity(0.1)
                                          : Colors.green[50]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
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
                                  borderRadius: BorderRadius.circular(12),
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
                            (isDark ? Colors.white : const Color(0xFF2E3A45)),
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
                                final userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                                userName = userData['name'] ?? 'Unknown';
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to build sanitization reports content
  Widget _buildSanitizationReportsContent(
      String adminUID, bool isDark, ThemeData theme) {
    Query approvedSanitizationQuery = FirebaseFirestore.instance
        .collection('sanitization')
        .where('status', isEqualTo: 'Approved')
        .where('Admin_UID', isEqualTo: adminUID);

    return StreamBuilder<QuerySnapshot>(
      stream: approvedSanitizationQuery.snapshots(),
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
              color: isDark ? Colors.greenAccent : const Color(0xFF43e97b),
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
                        color: (isDark ? Colors.greenAccent : Colors.green)
                            .withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Icon(
                    Icons.verified,
                    size: 80,
                    color:
                        isDark ? Colors.greenAccent : const Color(0xFF43e97b),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No approved sanitization reports found.',
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.textTheme.bodyLarge?.color ?? Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            String imageBase64 = data['image'] ?? '';
            String description = data['description'] ?? 'No description';
            String userId = data['userId'] ?? '';
            Timestamp? timestamp = data['timestamp'] as Timestamp?;
            String formattedDate = '';

            if (timestamp != null) {
              DateTime dateTime = timestamp.toDate();
              formattedDate =
                  '${dateTime.day}/${dateTime.month}/${dateTime.year}';
            }

            Uint8List? imageBytes;
            if (imageBase64.isNotEmpty) {
              try {
                imageBytes = base64Decode(imageBase64);
              } catch (e) {
                imageBytes = null;
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.greenAccent : Colors.green)
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
                                color:
                                    (isDark ? Colors.greenAccent : Colors.green)
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
                                          ? Colors.greenAccent.withOpacity(0.1)
                                          : Colors.green[50],
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      Icons.cleaning_services,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isDark
                                          ? Colors.greenAccent.withOpacity(0.2)
                                          : Colors.green[100]!,
                                      isDark
                                          ? Colors.greenAccent.withOpacity(0.1)
                                          : Colors.green[50]!,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
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
                                      Icons.verified,
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
                              // Date
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.blueAccent.withOpacity(0.1)
                                      : Colors.blue[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.blueAccent
                                        : Colors.blue,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: isDark
                                          ? Colors.blueAccent
                                          : Colors.blue[600],
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDate.isNotEmpty
                                          ? formattedDate
                                          : 'No date',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.blueAccent
                                            : Colors.blue[700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // User Name with FutureBuilder
                              FutureBuilder<String>(
                                future: _getUserNameForApprovedReports(userId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: isDark
                                                ? Colors.greenAccent
                                                : Colors.green,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Loading user...',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme
                                                .textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Text(
                                      'Error loading user',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    );
                                  }

                                  String userName =
                                      snapshot.data ?? 'Unknown User';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.purpleAccent.withOpacity(0.1)
                                          : Colors.purple[50],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.purpleAccent
                                            : Colors.purple,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: isDark
                                              ? Colors.purpleAccent
                                              : Colors.purple[600],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          userName,
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.purpleAccent
                                                : Colors.purple[700],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.textTheme.bodyLarge?.color,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Cleaned Button
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue[400]!,
                              Colors.blue[600]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _markSanitizationReportAsCleaned(
                              docs[index].id, context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.cleaning_services, size: 20),
                          label: const Text(
                            'Mark as Cleaned',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
    );
  }

  // Helper method to get user name for approved reports
  Future<String> _getUserNameForApprovedReports(String userId) async {
    try {
      print('_getUserNameForApprovedReports called with userId: "$userId"');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String name = userData['name'] ?? 'Unknown User';
        print('Resolved user name: "$name"');
        return name;
      } else {
        print('User document not found for userId: $userId');
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
  }

  // Method to mark sanitization report as cleaned
  Future<void> _markSanitizationReportAsCleaned(
      String reportId, BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Update the sanitization report status to 'Cleaned'
      await FirebaseFirestore.instance
          .collection('sanitization')
          .doc(reportId)
          .update({
        'status': 'Cleaned',
        'cleaned_at': FieldValue.serverTimestamp(),
        'cleaned_by': FirebaseAuth.instance.currentUser?.uid,
      });

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Sanitization report marked as cleaned successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Refresh the page by calling setState
      setState(() {});
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.pop(context);

      print('Error marking sanitization report as cleaned: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking report as cleaned: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
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

    print('ReportScreen build called');

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
                ],
              );
            },
          ),
          // Main content using StreamBuilder for real-time updates
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .snapshots(), // Show ALL reports for debugging
                builder: (context, snapshot) {
                  print('StreamBuilder state: ${snapshot.connectionState}');

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: isDark ? Colors.greenAccent : Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading reports...',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    print('FutureBuilder error: ${snapshot.error}');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[600],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error Loading Reports',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(color: Colors.red[600]),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {});
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data == null) {
                    print('StreamBuilder no data');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No Data Available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  print('StreamBuilder loaded ${docs.length} documents');

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
                            'No pending reports found.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color ??
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
                    itemCount: docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? '';
                      print('Document ${doc.id} has status: "$status"');
                      return status == 'Not Approved' ||
                          status == 'Pending' ||
                          status == 'not approved';
                    }).length,
                    itemBuilder: (context, index) {
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? '';
                        return status == 'Not Approved' ||
                            status == 'Pending' ||
                            status == 'not approved';
                      }).toList();

                      if (index < filteredDocs.length) {
                        return _buildReportCard(filteredDocs[index], context);
                      }
                      return Container(); // Fallback
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

  // Separate method to fetch reports with simpler error handling
  Future<List<QueryDocumentSnapshot>> _getNotApprovedReports() async {
    try {
      print('Attempting to fetch reports from Firestore...');

      // Ensure Firebase is initialized
      await Firebase.initializeApp();
      print('Firebase initialized');

      // Get Firestore instance
      final firestore = FirebaseFirestore.instance;
      print('Firestore instance obtained');

      // Try multiple query variations to handle different status values
      QuerySnapshot querySnapshot;

      // First try exact match
      querySnapshot = await firestore
          .collection('reports')
          .where('status', isEqualTo: 'Not Approved')
          .limit(20)
          .get();

      print('Query 1 (Not Approved): ${querySnapshot.docs.length} documents');

      // If no results, try other possible status values
      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await firestore
            .collection('reports')
            .where('status', isEqualTo: 'Pending')
            .limit(20)
            .get();
        print('Query 2 (Pending): ${querySnapshot.docs.length} documents');
      }

      // If still no results, try without status filter to see all reports
      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await firestore.collection('reports').limit(20).get();
        print('Query 3 (All reports): ${querySnapshot.docs.length} documents');

        // Print all statuses to debug
        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          print('Report ${doc.id} status: "${data['status']}"');
        }
      }

      print('Final query result: ${querySnapshot.docs.length} documents');
      return querySnapshot.docs;
    } catch (e, stackTrace) {
      print('Error fetching reports: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Method to approve a report
  Future<void> _approveReport(String reportId, BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Get current admin's UID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String currentAdminUID = currentUser.uid;

      // Update the report in Firebase
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': 'Approved',
        'Admin_UID': currentAdminUID,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report approved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Refresh the page by calling setState
      setState(() {});
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.pop(context);

      print('Error approving report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving report: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Helper method to build report cards
  Widget _buildReportCard(QueryDocumentSnapshot doc, BuildContext context) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final isDark = Theme.of(context).brightness == Brightness.dark;

      // Debug: Print all available fields
      print('Report data keys: ${data.keys.toList()}');
      print('Report data: $data');

      String imageBase64 = data['image'] ?? '';
      String reportId = doc.id;

      // Try multiple possible field names for complaint text
      String complaintText = data['complaint'] ??
          data['complaintText'] ??
          data['description'] ??
          data['text'] ??
          data['details'] ??
          data['message'] ??
          data['content'] ??
          'No description available';

      // Try multiple possible field names for category
      String category = data['category'] ??
          data['wasteType'] ??
          data['type'] ??
          data['waste_type'] ??
          'Uncategorized';

      // Debug logging
      print('Report ID: $reportId');
      print('Complaint text: "$complaintText"');
      print('Category: "$category"');
      print('Status: "${data['status']}"');
      print('Image data length: ${imageBase64.length}');

      // Decode base64 image
      Uint8List? imageBytes;
      if (imageBase64.isNotEmpty) {
        try {
          imageBytes = base64Decode(imageBase64);
          print('Successfully decoded image with ${imageBytes.length} bytes');
        } catch (e) {
          print('Error decoding base64 image: $e');
          imageBytes = null;
        }
      }

      // Also check if any field contains meaningful text
      if (complaintText == 'No description available') {
        print('All text fields were empty or null. Available fields:');
        data.forEach((key, value) {
          if (value is String && value.isNotEmpty) {
            print('  $key: "$value"');
          }
        });
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTap: () {
            // Navigate to detail page
            double latitude =
                (data['latitude'] is num) ? data['latitude'].toDouble() : 0.0;
            double longitude =
                (data['longitude'] is num) ? data['longitude'].toDouble() : 0.0;
            int quantity = data['quantity'] ?? 0;
            double weightPerKg = (data['weightPerKg'] is num)
                ? data['weightPerKg'].toDouble()
                : 0.0;
            String status = data['status'] ?? 'Not Approved';

            // Try multiple possible field names for userId
            String userId = data['userId'] ??
                data['user_id'] ??
                data['userID'] ??
                data['uid'] ??
                data['User_ID'] ??
                '';

            // Debug logging for userId
            print('Extracted userId from report: "$userId"');
            print('Available fields in report data: ${data.keys.toList()}');
            if (userId.isEmpty) {
              print(
                  'All userId field attempts failed. Checking for any user-related fields...');
              data.forEach((key, value) {
                if (key.toLowerCase().contains('user') ||
                    key.toLowerCase().contains('uid')) {
                  print('  Found user-related field: $key = "$value"');
                }
              });
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailScreen(
                  reportId: reportId,
                  complaintText: complaintText,
                  date: '',
                  quantity: quantity,
                  weightPerKg: weightPerKg,
                  status: status,
                  userId: userId,
                  imageBase64: imageBase64,
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
                (isDark ? Colors.greenAccent : Colors.green).withOpacity(0.3),
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Report Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isDark ? Colors.greenAccent : Colors.green)
                                      .withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageBytes != null
                              ? Image.memory(
                                  imageBytes,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.greenAccent.withOpacity(0.1)
                                        : Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          complaintText,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.greenAccent.withOpacity(0.2)
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.greenAccent.withOpacity(0.5)
                            : Colors.green[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isDark ? Colors.greenAccent : Colors.green[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.pending,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Pending Review',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error building report card: $e');
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading report'),
          ),
        ),
      );
    }
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
  late AnimationController _floatingController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isApproving = false; // Add loading state for approve button

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Method to fetch user name from Users collection
  Future<String> _getUserName(String userId) async {
    try {
      print('_getUserName called with userId: "$userId"');

      if (userId.isEmpty) {
        print('UserId is empty, returning Unknown User');
        return 'Unknown User';
      }

      print('Fetching user document for userId: $userId');
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      print('User document exists: ${userDoc.exists}');

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        print('User data: $userData');

        // Try different possible field names for the user's name
        String name = userData?['name'] ??
            userData?['displayName'] ??
            userData?['fullName'] ??
            userData?['email'] ??
            'Unknown User';

        print('Resolved user name: "$name"');
        return name;
      } else {
        print('User document does not exist for userId: $userId');
        return 'User Not Found';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Error Loading User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('reports')
                    .doc(widget.reportId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('StreamBuilder error: ${snapshot.error}');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[600],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Database Error',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.red[600]),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {});
                              },
                              child: Text('Retry'),
                            ),
                          ],
                        ),
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

                  // Add null check for snapshot.data
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No data available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  }

                  final doc = snapshot.data!;
                  if (!doc.exists) {
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

                  // Get the report data
                  final data = doc.data() as Map<String, dynamic>;
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Report details card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 6,
                          shadowColor:
                              (isDark ? Colors.greenAccent : Colors.green)
                                  .withOpacity(0.3),
                          color:
                              isDark ? const Color(0xFF2A2A2A) : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  'Report Details',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Report information
                                _buildDetailRow(
                                    'Complaint', widget.complaintText, isDark),

                                // User name with FutureBuilder
                                FutureBuilder<String>(
                                  future: _getUserName(widget.userId),
                                  builder: (context, snapshot) {
                                    print(
                                        'FutureBuilder state: ${snapshot.connectionState}');
                                    print(
                                        'FutureBuilder hasError: ${snapshot.hasError}');
                                    print(
                                        'FutureBuilder data: ${snapshot.data}');
                                    print(
                                        'widget.userId in FutureBuilder: "${widget.userId}"');

                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return _buildDetailRow(
                                          'Reported by', 'Loading...', isDark);
                                    } else if (snapshot.hasError) {
                                      print(
                                          'FutureBuilder error: ${snapshot.error}');
                                      return _buildDetailRow('Reported by',
                                          'Error: ${snapshot.error}', isDark);
                                    } else {
                                      String userName =
                                          snapshot.data ?? 'Unknown User';
                                      print(
                                          'Final userName to display: "$userName"');
                                      return _buildDetailRow(
                                          'Reported by', userName, isDark);
                                    }
                                  },
                                ),

                                _buildDetailRow(
                                    'Category', widget.category, isDark),
                                _buildDetailRow(
                                    'Status', widget.status, isDark),
                                _buildDetailRow('Quantity',
                                    widget.quantity.toString(), isDark),
                                _buildDetailRow('Weight per Kg',
                                    widget.weightPerKg.toString(), isDark),

                                // Image if available
                                if (widget.imageBase64.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    'Image',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      base64Decode(widget.imageBase64),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],

                                // Location info
                                if (widget.latitude != 0.0 &&
                                    widget.longitude != 0.0) ...[
                                  const SizedBox(height: 20),
                                  Text(
                                    'Location',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildDetailRow('Latitude',
                                      widget.latitude.toString(), isDark),
                                  _buildDetailRow('Longitude',
                                      widget.longitude.toString(), isDark),
                                ],

                                // Approve Report Button (only show if status is not approved)
                                if (widget.status != 'Approved') ...[
                                  const SizedBox(height: 30),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isApproving
                                          ? null
                                          : () => _approveReportDetail(context),
                                      icon: _isApproving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.check_circle,
                                              size: 20),
                                      label: Text(
                                        _isApproving
                                            ? 'Approving...'
                                            : 'Approve Report',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: isDark
                                            ? Colors.greenAccent
                                            : Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        elevation: 4,
                                        shadowColor:
                                            Colors.green.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to approve a report from the detail view
  Future<void> _approveReportDetail(BuildContext context) async {
    // Set loading state
    setState(() {
      _isApproving = true;
    });

    try {
      // Get current admin's UID immediately - no loading dialog needed
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _isApproving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      String currentAdminUID = currentUser.uid;

      // Update the report in Firebase - this is usually very fast
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .update({
        'status': 'Approved',
        'Admin_UID': currentAdminUID,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Reset loading state
      setState(() {
        _isApproving = false;
      });

      // Show quick success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Report approved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500), // Shorter duration
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Navigate back immediately
      Navigator.pop(context);
    } catch (e) {
      // Reset loading state on error
      setState(() {
        _isApproving = false;
      });

      print('Error approving report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving report: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Helper method for building detail rows
  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sanitization Reports Screen
class SanitizationReportsScreen extends StatefulWidget {
  const SanitizationReportsScreen({Key? key}) : super(key: key);

  @override
  _SanitizationReportsScreenState createState() =>
      _SanitizationReportsScreenState();
}

class _SanitizationReportsScreenState extends State<SanitizationReportsScreen>
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

  String _formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<String> _getUserName(String userId) async {
    try {
      print('_getUserName called with userId: "$userId"');
      print('Fetching user document for userId: $userId');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      print('User document exists: ${userDoc.exists}');

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('User data: $userData');
        String name = userData['name'] ?? 'Unknown User';
        print('Resolved user name: "$name"');
        return name;
      } else {
        print('User document not found for userId: $userId');
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
          'Pending Sanitization Reports',
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
                    top: 300 + (_floatingController.value * -15),
                    right: 30 + (_floatingController.value * 25),
                    child: Opacity(
                      opacity: isDark ? 0.03 : 0.08,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? Colors.greenAccent : Colors.green[200],
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
                stream: FirebaseFirestore.instance
                    .collection('sanitization')
                    .where('status', isEqualTo: 'Pending')
                    .snapshots(),
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
                              Icons.cleaning_services,
                              size: 80,
                              color: isDark
                                  ? Colors.greenAccent
                                  : const Color(0xFF43e97b),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No pending sanitization reports found.',
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

                      String description =
                          data['description'] ?? 'No description';
                      String userId = data['userId'] ?? '';
                      String timestamp =
                          data['timestamp']?.toDate().toString() ?? '';
                      String formattedDate = _formatDate(timestamp);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
                              // Header Row with Image and Info
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
                                                Icons.cleaning_services,
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
                                                    ? Colors.orangeAccent
                                                        .withOpacity(0.2)
                                                    : Colors.orange[100]!,
                                                isDark
                                                    ? Colors.orangeAccent
                                                        .withOpacity(0.1)
                                                    : Colors.orange[50]!,
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.orangeAccent
                                                  : Colors.orange,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.pending,
                                                color: isDark
                                                    ? Colors.orangeAccent
                                                    : Colors.orange[600],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Pending',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.orangeAccent
                                                      : Colors.orange[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Date
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.blueAccent
                                                    .withOpacity(0.1)
                                                : Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.blueAccent
                                                  : Colors.blue,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                color: isDark
                                                    ? Colors.blueAccent
                                                    : Colors.blue[600],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.blueAccent
                                                      : Colors.blue[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // User Name with FutureBuilder
                                        FutureBuilder<String>(
                                          future: _getUserName(userId),
                                          builder: (context, snapshot) {
                                            print(
                                                'FutureBuilder state: ${snapshot.connectionState}');
                                            print(
                                                'FutureBuilder hasError: ${snapshot.hasError}');
                                            print(
                                                'FutureBuilder data: ${snapshot.data}');
                                            print(
                                                'widget.userId in FutureBuilder: "$userId"');

                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Row(
                                                children: [
                                                  SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: isDark
                                                          ? Colors.greenAccent
                                                          : Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Loading user...',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: theme.textTheme
                                                          .bodySmall?.color,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }

                                            if (snapshot.hasError) {
                                              return Text(
                                                'Error loading user',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                ),
                                              );
                                            }

                                            String userName =
                                                snapshot.data ?? 'Unknown User';
                                            print(
                                                'Final userName to display: "$userName"');

                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.purpleAccent
                                                        .withOpacity(0.1)
                                                    : Colors.purple[50],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.purpleAccent
                                                      : Colors.purple,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.person,
                                                    color: isDark
                                                        ? Colors.purpleAccent
                                                        : Colors.purple[600],
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    userName,
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? Colors.purpleAccent
                                                          : Colors.purple[700],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Description
                              Text(
                                description,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.textTheme.titleLarge?.color ??
                                      (isDark
                                          ? Colors.white
                                          : const Color(0xFF2E3A45)),
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 20),
                              // Action Buttons Row
                              Row(
                                children: [
                                  // Approve Button
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green[400]!,
                                            Colors.green[600]!
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.green.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _approveSanitizationReport(
                                                reportId, context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        icon: const Icon(
                                            Icons.check_circle_outline,
                                            size: 20),
                                        label: const Text(
                                          'Approve',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Deny Button
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.red[400]!,
                                            Colors.red[600]!
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _denySanitizationReport(
                                                reportId, context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        icon: const Icon(Icons.cancel_outlined,
                                            size: 20),
                                        label: const Text(
                                          'Deny',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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

  // Method to approve sanitization report
  Future<void> _approveSanitizationReport(
      String reportId, BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Get current admin's UID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String currentAdminUID = currentUser.uid;

      // Update the sanitization report in Firebase
      await FirebaseFirestore.instance
          .collection('sanitization')
          .doc(reportId)
          .update({
        'status': 'Approved',
        'Admin_UID': currentAdminUID,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sanitization report approved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Refresh the page by calling setState
      setState(() {});
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.pop(context);

      print('Error approving sanitization report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving sanitization report: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Method to deny (delete) sanitization report
  Future<void> _denySanitizationReport(
      String reportId, BuildContext context) async {
    // Show confirmation dialog first
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deny Report'),
          content: const Text(
            'Are you sure you want to deny this sanitization report? This action will permanently delete the report and cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // If user confirmed deletion
    if (shouldDelete == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        // Delete the sanitization report from Firebase
        await FirebaseFirestore.instance
            .collection('sanitization')
            .doc(reportId)
            .delete();

        // Close loading dialog
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Sanitization report denied and deleted successfully!'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Refresh the page by calling setState
        setState(() {});
      } catch (e) {
        // Close loading dialog if it's open
        Navigator.pop(context);

        print('Error denying sanitization report: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error denying sanitization report: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

// Approved Sanitization Reports Screen
class ApprovedSanitizationReportsScreen extends StatefulWidget {
  const ApprovedSanitizationReportsScreen({Key? key}) : super(key: key);

  @override
  _ApprovedSanitizationReportsScreenState createState() =>
      _ApprovedSanitizationReportsScreenState();
}

class _ApprovedSanitizationReportsScreenState
    extends State<ApprovedSanitizationReportsScreen>
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

  Future<String> _getUserName(String userId) async {
    try {
      print('_getUserName called with userId: "$userId"');
      print('Fetching user document for userId: $userId');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      print('User document exists: ${userDoc.exists}');

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('User data: $userData');
        String name = userData['name'] ?? 'Unknown User';
        print('Resolved user name: "$name"');
        return name;
      } else {
        print('User document not found for userId: $userId');
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name: $e');
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get current user for filtering
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Approved Sanitization Reports'),
        ),
        body: const Center(
          child: Text('Error: No authenticated user found'),
        ),
      );
    }

    Query approvedSanitizationQuery = FirebaseFirestore.instance
        .collection('sanitization')
        .where('status', isEqualTo: 'Approved')
        .where('Admin_UID', isEqualTo: currentUser.uid);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
          'Approved Sanitization Reports',
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
                    right: 40 + (_floatingController.value * 35),
                    child: Opacity(
                      opacity: isDark ? 0.03 : 0.08,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isDark ? Colors.greenAccent : Colors.green[200],
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
                stream: approvedSanitizationQuery.snapshots(),
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
                              Icons.verified,
                              size: 80,
                              color: isDark
                                  ? Colors.greenAccent
                                  : const Color(0xFF43e97b),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No approved sanitization reports found.',
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
                      String description =
                          data['description'] ?? 'No description';
                      String userId = data['userId'] ?? '';
                      Timestamp? timestamp = data['timestamp'] as Timestamp?;
                      String formattedDate = '';

                      if (timestamp != null) {
                        DateTime dateTime = timestamp.toDate();
                        formattedDate =
                            '${dateTime.day}/${dateTime.month}/${dateTime.year}';
                      }

                      Uint8List? imageBytes;
                      if (imageBase64.isNotEmpty) {
                        try {
                          imageBytes = base64Decode(imageBase64);
                        } catch (e) {
                          imageBytes = null;
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
                                                Icons.cleaning_services,
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
                                                Icons.verified,
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
                                        // Date
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.blueAccent
                                                    .withOpacity(0.1)
                                                : Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.blueAccent
                                                  : Colors.blue,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                color: isDark
                                                    ? Colors.blueAccent
                                                    : Colors.blue[600],
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                formattedDate.isNotEmpty
                                                    ? formattedDate
                                                    : 'No date',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.blueAccent
                                                      : Colors.blue[700],
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // User Name with FutureBuilder
                                        FutureBuilder<String>(
                                          future: _getUserName(userId),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Row(
                                                children: [
                                                  SizedBox(
                                                    width: 12,
                                                    height: 12,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: isDark
                                                          ? Colors.greenAccent
                                                          : Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Loading user...',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: theme.textTheme
                                                          .bodySmall?.color,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }

                                            if (snapshot.hasError) {
                                              return Text(
                                                'Error loading user',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                ),
                                              );
                                            }

                                            String userName =
                                                snapshot.data ?? 'Unknown User';

                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.purpleAccent
                                                        .withOpacity(0.1)
                                                    : Colors.purple[50],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.purpleAccent
                                                      : Colors.purple,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.person,
                                                    color: isDark
                                                        ? Colors.purpleAccent
                                                        : Colors.purple[600],
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    userName,
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? Colors.purpleAccent
                                                          : Colors.purple[700],
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Description
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.textTheme.bodyLarge?.color,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
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
