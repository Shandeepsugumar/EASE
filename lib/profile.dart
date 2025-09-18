import 'package:ease/home_page.dart';
import 'package:ease/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Profile Page with improved UI and no profile photo edit
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<Map<String, dynamic>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        return docSnapshot.data()!;
      }
    }
    return {};
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  void _logout(BuildContext context) async {
    try {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Sign out from FirebaseAuth
      await FirebaseAuth.instance.signOut();

      // Handle Google Sign-In logout
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (e) {
        // Ignore disconnect errors as the session might already be invalid
        debugPrint('Google disconnect error: $e');
      }

      // Clear app data from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Remove the loading indicator
      Navigator.of(context).pop();

      // Navigate to the starting screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginApp()),
      );
    } catch (e) {
      // Remove loading indicator if error occurs
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  // Navigate to the Edit Profile page
  void _editProfile(Map<String, dynamic> userData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(userData: userData),
      ),
    ).then((_) {
      // Refresh data after returning from the edit page.
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 2,
        centerTitle: true,
        title: Text(
          "Profile",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: Icon(Icons.logout, color: Colors.redAccent, size: 18),
              label: Text("Logout",
                  style: TextStyle(color: Colors.redAccent, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.redAccent, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    colorScheme.surface.withOpacity(0.8),
                    colorScheme.primary.withOpacity(0.1),
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    Color(0xFFe8f5e9),
                    Color(0xFFb2f7ef),
                    theme.scaffoldBackgroundColor,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            final isDark = theme.brightness == Brightness.dark;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error fetching user data',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No user data available',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              );
            } else {
              final userData = snapshot.data!;
              final name = userData['name'] ?? 'No Name';
              final phone = userData['phone'] ?? 'No Phone';
              final profileUrl =
                  userData['profile'] ?? 'https://via.placeholder.com/150';
              final totalScore = userData['totalScore'] ?? 0;
              final lastCompletion = userData['lastTaskCompletion'] != null
                  ? (userData['lastTaskCompletion'] as Timestamp).toDate()
                  : DateTime.now();
              final streakCount = userData['streakCount'] ?? 0;
              final now = DateTime.now();
              final isStreakActive = now.difference(lastCompletion).inDays <= 1;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),
                      // Floating profile picture with shadow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.18),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 64,
                          backgroundColor: colorScheme.surface,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(profileUrl),
                          ),
                        ),
                      ),
                      SizedBox(height: 28),
                      // Solid white profile info card (no glassmorphic)
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        color: isDark ? colorScheme.surface : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Phone: $phone',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: 24),
                              // Gradient Edit Profile button
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            colorScheme.primary,
                                            colorScheme.primary.withOpacity(0.8)
                                          ]
                                        : [
                                            Color(0xFF43e97b),
                                            Color(0xFF38f9d7)
                                          ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          colorScheme.primary.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => _editProfile(userData),
                                  icon: Icon(
                                    Icons.edit,
                                    color: isDark
                                        ? colorScheme.onPrimary
                                        : Colors.white,
                                  ),
                                  label: Text(
                                    "Edit Profile",
                                    style: TextStyle(
                                      color: isDark
                                          ? colorScheme.onPrimary
                                          : Colors.white,
                                      fontSize: 17,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 28, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 36),
                      // Stats with theme colors
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ElegantStatCard(
                            icon: Icons.score,
                            label: 'Total Score',
                            value: '$totalScore',
                            color: isDark
                                ? colorScheme.secondary
                                : Colors.blueAccent,
                            isDark: isDark,
                            colorScheme: colorScheme,
                          ),
                          _ElegantStatCard(
                            icon: Icons.whatshot,
                            label: 'Streak',
                            value: isStreakActive
                                ? '$streakCount days'
                                : 'No streak',
                            color: isStreakActive
                                ? (isDark ? colorScheme.primary : Colors.green)
                                : Colors.redAccent,
                            isDark: isDark,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      _ElegantStatCard(
                        icon: Icons.calendar_today,
                        label: 'Last Completion',
                        value: '${lastCompletion.toLocal()}'.split(' ')[0],
                        color: isDark ? colorScheme.tertiary : Colors.orange,
                        isDark: isDark,
                        colorScheme: colorScheme,
                      ),
                      SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

// Edit Profile Page allowing the user to update their details (excluding profile photo)
class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  EditProfilePage({required this.userData});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _phone;

  @override
  void initState() {
    super.initState();
    _name = widget.userData['name'] ?? '';
    _phone = widget.userData['phone'] ?? '';
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDoc.update({
          'name': _name,
          'phone': _phone,
        });
        // After successful save, redirect to Homepage (MyApp)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage(user: user)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    colorScheme.surface.withOpacity(0.8),
                    colorScheme.primary.withOpacity(0.1),
                    theme.scaffoldBackgroundColor,
                  ]
                : [
                    Color(0xFFe8f5e9),
                    Color(0xFFb2f7ef),
                    theme.scaffoldBackgroundColor,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Custom full-screen app bar
            Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.primary.withOpacity(0.9)
                    : colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Edit Profile",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 30),

                          // Profile Picture Section
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 70,
                              backgroundColor:
                                  isDark ? colorScheme.surface : Colors.white,
                              child: CircleAvatar(
                                radius: 65,
                                backgroundImage: NetworkImage(
                                    widget.userData['profile'] ??
                                        'https://via.placeholder.com/150'),
                                backgroundColor: Colors.grey[300],
                                child: widget.userData['profile'] == null
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey[600],
                                      )
                                    : null,
                              ),
                            ),
                          ),

                          SizedBox(height: 20),

                          // User name display
                          Text(
                            widget.userData['name'] ?? 'User Name',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),

                          SizedBox(height: 30),

                          // Form Card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? colorScheme.surface.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Personal Information",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? colorScheme.primary
                                        : colorScheme.primary,
                                  ),
                                ),
                                SizedBox(height: 24),

                                // Name Field
                                TextFormField(
                                  initialValue: _name,
                                  style: TextStyle(
                                    color: Colors.white, // White text
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    labelStyle: TextStyle(
                                      color:
                                          Colors.grey[400], // Light grey label
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color:
                                          Colors.grey[400], // Light grey icon
                                    ),
                                    filled: true,
                                    fillColor: Colors
                                        .grey[800], // Light black background
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                          color: colorScheme.primary, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                  ),
                                  onSaved: (value) => _name = value!,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? "Enter your name"
                                          : null,
                                ),
                                SizedBox(height: 20),

                                // Phone Field
                                TextFormField(
                                  initialValue: _phone,
                                  style: TextStyle(
                                    color: Colors.white, // White text
                                    fontSize: 16,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number',
                                    labelStyle: TextStyle(
                                      color:
                                          Colors.grey[400], // Light grey label
                                    ),
                                    prefixIcon: Icon(
                                      Icons.phone_outlined,
                                      color:
                                          Colors.grey[400], // Light grey icon
                                    ),
                                    filled: true,
                                    fillColor: Colors
                                        .grey[800], // Light black background
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                          color: colorScheme.primary, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                  ),
                                  onSaved: (value) => _phone = value!,
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? "Enter your phone number"
                                          : null,
                                ),

                                SizedBox(height: 32),

                                // Save Button
                                Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [
                                              colorScheme.primary,
                                              colorScheme.primary
                                                  .withOpacity(0.8)
                                            ]
                                          : [
                                              colorScheme.primary,
                                              colorScheme.primary
                                                  .withOpacity(0.7)
                                            ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _saveProfile,
                                    icon: Icon(
                                      Icons.save_outlined,
                                      color: colorScheme.onPrimary,
                                    ),
                                    label: Text(
                                      "Save Changes",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Elegant stat card widget for profile stats with theme support
class _ElegantStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final ColorScheme colorScheme;

  const _ElegantStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isDark ? colorScheme.surface : Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? colorScheme.onSurface : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
