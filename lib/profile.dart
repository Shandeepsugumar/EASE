import 'package:ease/home_page.dart';
import 'package:ease/login.dart';
import 'package:ease/main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'localization/app_localizations.dart';
import 'state/app_state.dart';
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppTopBar(
        title: Text(l.profile),
        actions: [
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: Text(l.logout, style: const TextStyle(color: Colors.redAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe8f5e9), Color(0xFFb2f7ef), Colors.white],
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
              final profileUrl = userData['profile'] ?? 'https://via.placeholder.com/150';
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
                      SizedBox(height: 30),
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
                          backgroundColor: Colors.white,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green[900])),
                              SizedBox(height: 10),
                              Text('Phone: $phone', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                              SizedBox(height: 24),
                              // Gradient Edit Profile button
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
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
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  label: Text(l.editProfile, style: const TextStyle(color: Colors.white, fontSize: 17)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
                          ),
                          _ElegantStatCard(
                            icon: Icons.whatshot,
                            label: l.streak,
                            value: isStreakActive ? '$streakCount ${l.days}' : l.noStreak,
                            color: isStreakActive ? Colors.green : Colors.redAccent,
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      _ElegantStatCard(
                        icon: Icons.calendar_today,
                        label: l.lastCompletion,
                        value: '${lastCompletion.toLocal()}'.split(' ')[0],
                        color: Colors.orange,
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          // Background image with white fading effect.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/assets/ease.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.3)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          // Form content.
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  // Name Field
                  TextFormField(
                    initialValue: _name,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSaved: (value) => _name = value!,
                    validator: (value) =>
                    value == null || value.isEmpty ? "Enter your name" : null,
                  ),
                  SizedBox(height: 20),
                  // Phone Field
                  TextFormField(
                    initialValue: _phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSaved: (value) => _phone = value!,
                    validator: (value) => value == null || value.isEmpty
                        ? "Enter your phone number"
                        : null,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text(
                      "Save Changes",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 15.0),
                      textStyle:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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

// Elegant stat card widget for profile stats
class _ElegantStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ElegantStatCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 7),
            Text(label, style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.w600)),
            SizedBox(height: 3),
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
