import 'package:ease/home_page.dart';
import 'package:ease/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization/app_localizations.dart';
import 'widgets/app_top_bar.dart';

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
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      appBar: AppTopBar(
        title: Text(l.profile),
        actions: [
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label:
                Text(l.logout, style: const TextStyle(color: Colors.redAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: isDark ? Colors.grey[800] : Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey[900]!, Colors.grey[800]!, Colors.grey[850]!]
                : [Color(0xFFe8f5e9), Color(0xFFb2f7ef), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text(l.error));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(l.error));
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
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          height:
                              80), // Increased from 30 to 80 to account for navbar
                      // Floating profile picture with shadow
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.18),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 64,
                          backgroundColor:
                              isDark ? Colors.grey[700] : Colors.white,
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
                        color: isDark ? Colors.grey[850] : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: isDark
                                              ? Colors.greenAccent
                                              : Colors.green[900])),
                              SizedBox(height: 10),
                              Text('Phone: $phone',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700])),
                              SizedBox(height: 24),
                              // Gradient Edit Profile button
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF43e97b),
                                      Color(0xFF38f9d7)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => _editProfile(userData),
                                  icon: Icon(Icons.edit,
                                      color:
                                          isDark ? Colors.black : Colors.white),
                                  label: Text(l.editProfile,
                                      style: TextStyle(
                                          color: isDark
                                              ? Colors.black
                                              : Colors.white,
                                          fontSize: 17)),
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
                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ElegantStatCard(
                            icon: Icons.score,
                            label: l.totalScore,
                            value: '$totalScore',
                            color: Colors.blueAccent,
                            isDark: isDark,
                          ),
                          _ElegantStatCard(
                            icon: Icons.whatshot,
                            label: l.streak,
                            value: isStreakActive
                                ? '$streakCount ${l.days}'
                                : l.noStreak,
                            color: isStreakActive
                                ? Colors.green
                                : Colors.redAccent,
                            isDark: isDark,
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      _ElegantStatCard(
                        icon: Icons.calendar_today,
                        label: l.lastCompletion,
                        value: '${lastCompletion.toLocal()}'.split(' ')[0],
                        color: Colors.orange,
                        isDark: isDark,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          // Custom App Bar that covers the full top
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.green[800],
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
                      color: Colors.white,
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
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 40),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(height: 20),

                  // Profile Picture Section
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? Colors.greenAccent : Colors.green)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.white,
                      child: CircleAvatar(
                        radius: 75,
                        backgroundImage: NetworkImage(
                            widget.userData['profile'] ??
                                'https://via.placeholder.com/150'),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Form Section
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Personal Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.greenAccent
                                  : Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 24),

                          // Name Field
                          _buildModernTextField(
                            initialValue: _name,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            isDark: isDark,
                            onSaved: (value) => _name = value!,
                            validator: (value) => value == null || value.isEmpty
                                ? "Enter your name"
                                : null,
                          ),

                          SizedBox(height: 20),

                          // Phone Field
                          _buildModernTextField(
                            initialValue: _phone,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            isDark: isDark,
                            keyboardType: TextInputType.phone,
                            onSaved: (value) => _phone = value!,
                            validator: (value) => value == null || value.isEmpty
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
                                    ? [Colors.greenAccent, Colors.green]
                                    : [Colors.green[600]!, Colors.green[800]!],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                          ? Colors.greenAccent
                                          : Colors.green)
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
                                color: isDark ? Colors.black : Colors.white,
                              ),
                              label: Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.black : Colors.white,
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
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required String initialValue,
    required String label,
    required IconData icon,
    required bool isDark,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            icon,
            color: isDark ? Colors.greenAccent : Colors.green[600],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? Colors.greenAccent : Colors.green,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }
}

// Elegant stat card widget for profile stats
class _ElegantStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _ElegantStatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 15, color: color, fontWeight: FontWeight.w600)),
            SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }
}
