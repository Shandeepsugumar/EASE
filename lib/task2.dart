import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpcyclingChallengeScreen extends StatefulWidget {
  @override
  _UpcyclingChallengeScreenState createState() => _UpcyclingChallengeScreenState();
}

class _UpcyclingChallengeScreenState extends State<UpcyclingChallengeScreen> {
  File? upcycledPhoto;
  bool taskSubmitted = false;
  bool isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _verificationRecord;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  /// Query Firestore for a verification record with current user and level 2.
  Future<void> _checkVerificationStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('verify')
          .where('userId', isEqualTo: currentUser.uid)
          .where('level', isEqualTo: 2)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _verificationRecord = querySnapshot.docs.first.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print('Error checking verification status: $e');
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo != null) {
        setState(() {
          upcycledPhoto = File(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error capturing photo: ${e.toString()}")),
      );
    }
  }

  Future<void> _submitTask() async {
    // Check if a photo has been captured.
    if (upcycledPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please capture a photo of your upcycled item.")),
      );
      return;
    }

    // Ensure a user is authenticated.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not authenticated. Please log in.")),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final photoBytes = await upcycledPhoto!.readAsBytes();
      final String photoBase64 = base64Encode(photoBytes);

      Map<String, dynamic> upcyclingData = {
        'userId': currentUser.uid,
        'photo': photoBase64,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Not Confirmed',
        'points': 0,
        'level': 2,
      };

      // Store the data in the "verify" collection.
      await FirebaseFirestore.instance.collection('verify').add(upcyclingData);

      setState(() {
        taskSubmitted = true;
      });

      // Refresh the verification status.
      await _checkVerificationStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting task: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  /// Build the photo section.
  Widget _buildPhotoSection() {
    // If verification record exists, display the photo from Base64.
    if (_verificationRecord != null) {
      String base64Str = _verificationRecord!['photo'];
      Uint8List imageBytes = base64Decode(base64Str);
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(vertical: 8),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upcycled Item Photo",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(imageBytes, width: double.infinity, height: 200, fit: BoxFit.cover),
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise, allow photo capture.
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(vertical: 8),
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Upcycled Item Photo",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: upcycledPhoto != null
                  ? Image.file(upcycledPhoto!, width: double.infinity, height: 200, fit: BoxFit.cover)
                  : Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.camera_alt, size: 50, color: Colors.grey[700]),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _capturePhoto,
                icon: Icon(Icons.camera, color: Colors.white),
                label: Text("Capture Photo", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the verification status card.
  Widget _buildVerificationMessage() {
    bool isNotConfirmed = _verificationRecord!['status'] == 'Not Confirmed';
    String message = isNotConfirmed
        ? "Verification in Progress. Once verified, points will be added in your piggy bank. Whooah!"
        : "Thanks for Completing this Task and keep motivated to do the remainings..";
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            message,
            style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If a verification record exists, disable further photo capture and submission.
    bool verificationExists = _verificationRecord != null;

    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          "Upcycling Challenge",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blueAccent, size: 28),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Upcycling Challenge Info",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    content: Text(
                      "This challenge encourages you to repurpose common household items into creative new uses. "
                          "For example, turn old glass jars into planters or repurpose T-shirts into cleaning rags. "
                          "Capture a clear photo of your creation and share it to inspire others!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "OK",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Task Description Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.autorenew, color: Colors.green.shade700, size: 28),
                            SizedBox(width: 8),
                            Text(
                              "Upcycling Challenge",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        SizedBox(height: 8),
                        Text(
                          "Task: Repurpose common household items—such as turning old glass jars into planters or T-shirts into cleaning rags.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // How to Do It Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row with Icon and Title
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blueAccent,
                              size: 28,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "How to Do It:",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        SizedBox(height: 12),
                        Text(
                          "1. Look around your home for items you no longer use, such as old glass jars or worn-out T-shirts.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "2. Brainstorm creative ways to repurpose these items — for example, transform a glass jar into a planter or convert a T-shirt into a cleaning rag.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "3. Implement your idea and craft your own upcycled item.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "4. Capture a clear and well-lit photo of your finished creation.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Display photo section (read-only if verified)
                _buildPhotoSection(),
                SizedBox(height: 16),
                // If verification record exists, show verification message; otherwise, show submit button.
                verificationExists
                    ? _buildVerificationMessage()
                    : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting ? null : _submitTask,
                  icon: isSubmitting
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Icon(Icons.send, color: Colors.white),
                  label: Text(
                    isSubmitting ? "Submitting..." : "Submit Entry",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
