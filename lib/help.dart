import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui'; // For ImageFilter
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ease/wellness_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:googleapis/datamigration/v1.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart'; // Add share_plus dependency
import 'localization/app_localizations.dart';
import 'widgets/app_top_bar.dart';

class HelpPage extends StatelessWidget {
  final Map<String, dynamic> nearestOfficer;
  final File image;
  final String text;
  final String category;

  HelpPage({
    required this.nearestOfficer,
    required this.image,
    required this.text,
    required this.category
  });
  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in kilometers.
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);
  // Function to launch the dialer or initiate a phone call.
  void _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isNotEmpty) {
      final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      }
    } else {
      print("Invalid phone number");
    }
  }

  // Function to open Google Maps with latitude & longitude from a string.
  void _openGoogleMaps(BuildContext context) async {
    final String? latLong = nearestOfficer['latlong'];

    if (latLong != null && latLong.contains(",")) {
      final List<String> coordinates = latLong.split(",");
      if (coordinates.length == 2) {
        final double latitude = double.tryParse(coordinates[0].trim()) ?? 0.0;
        final double longitude = double.tryParse(coordinates[1].trim()) ?? 0.0;

        if (latitude != 0.0 && longitude != 0.0) {
          final Uri mapsUrl = Uri.parse(
              "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude");

          if (await canLaunchUrl(mapsUrl)) {
            await launchUrl(mapsUrl);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Could not open Google Maps")),
            );
          }
          return;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invalid location format")),
    );
  }
  Future<geo.Position> _getUserLocation() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    geo.LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == geo.LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    return await geo.Geolocator.getCurrentPosition();
  }

  void _raiseComplaint(BuildContext context, File imageFile, String userId, String category) async {
    String complaintText = '';
    int quantity = 0;
    double weightPerKg = 0.0;
    DateTime date = DateTime.now();
    String status = 'Not Approved';

    // ✅ Convert File to Base64
    String base64Image = '';
    List<int> imageBytes = await imageFile.readAsBytes();
    base64Image = base64Encode(imageBytes);
  
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Raise Complaint',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: FileImage(imageFile),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildInputField(
                  label: 'Quantity',
                  hintText: 'Enter quantity',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => quantity = int.tryParse(value) ?? 0,
                ),

                const SizedBox(height: 16),

                _buildInputField(
                  label: 'Weight per kg',
                  hintText: 'Enter weight',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => weightPerKg = double.tryParse(value) ?? 0.0,
                ),

                const SizedBox(height: 16),

                TextField(
                  onChanged: (value) => complaintText = value,
                  decoration: InputDecoration(
                    hintText: 'Describe your complaint...',
                    labelText: 'Complaint Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (complaintText.isNotEmpty && quantity > 0 && weightPerKg > 0) {
                  // Save the complaint (await if your saveComplaint returns a Future)
                  await saveComplaint(
                    userId: userId,
                    category: category,
                    complaintText: complaintText,
                    quantity: quantity,
                    weightPerKg: weightPerKg,
                    date: date,
                    status: status,
                    base64Image: base64Image,
                  );

                  // Close the dialog
                  Navigator.of(context).pop();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complaint submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // After a delay, navigate to WellnessPage
                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => WellnessPage()),
                    );
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Submit',style: TextStyle(color: Colors.white),),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      }
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextInputType keyboardType,
    required Function(String) onChanged,
  }) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: onChanged,
    );
  }


// ✅ Save complaint to collection (Example function)
  Future<void> saveComplaint({
    required String userId,
    required String category,
    required String complaintText,
    required int quantity,
    required double weightPerKg,
    required DateTime date,
    required String status,
    required String base64Image,
  }) async {
    try {
      // Request location permission
      geo.LocationPermission permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied || permission == geo.LocationPermission.deniedForever) {
        print("Location permission denied.");
        return;
      }

      // Get current position
      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      // Save to Firestore
      await FirebaseFirestore.instance.collection('reports').add({
        'userId': userId,
        'category': category,
        'complaintText': complaintText,
        'quantity': quantity,
        'weightPerKg': weightPerKg,
        'date': date.toIso8601String(),
        'status': status,
        'image': base64Image,
        'latitude': position.latitude,  // Storing latitude
        'longitude': position.longitude, // Storing longitude
      });

      print("Complaint saved successfully with location!");
    } catch (e) {
      print("Error saving complaint: $e");
    }
  }

  // Function to share a report via WhatsApp (using share_plus)
  Future<void> _sendReportViaWhatsApp(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Honourable Citizen';

      // Prepare the report text
      final String reportLetter =
          "Dear Officer,\n\n"
          "I am writing to report an incident. Please find the details below:\n\n"
          "Description:\n$text\n\n"
          "Thank you,\n$userName";

      const String phoneNumber = "+917010161033";
      final String whatsappUrl = "https://wa.me/$phoneNumber?text=$reportLetter";

      // ✅ Open WhatsApp URL
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to open WhatsApp.")),
        );
      }
    } catch (e) {
      print("⚠️ Error sending report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send report. Please try again.")),
      );
    }
  }

  // Updated _onCardTap that launches the Google Maps link from the document.
  void _onCardTap(BuildContext context, DocumentSnapshot result) async {
    final String link = result.get('link') ?? "";
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No map link available.")),
      );
      return;
    }
    final Uri mapsUri = Uri.parse(link);
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch Google Maps.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppTopBar(title: Text(l.helpNearestOfficer)),
      body: Stack(
        children: [
          // Background image from assets.
          Positioned.fill(
            child: Image.asset(
              'lib/assets/ease.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // White fading effect overlay.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          // Main content wrapped in a SingleChildScrollView for full-page scrolling.
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Section with Animated Fade-in and Orange Gradient Overlay.
                Stack(
                  children: [
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 800),
                      curve: Curves.easeIn,
                      child: Container(
                        height: 250,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.orange.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Text(
                        "Emergency Assistance",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.black45,
                              offset: Offset(2, 2),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Officer Details Card.
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Background: white fading effect with an asset image overlay.
                            Container(
                              height: 400, // Adjust height as needed.
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.9),
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                            // Asset image as background (optional).
                            Positioned.fill(
                              child: Image.asset(
                                'lib/assets/ease.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                            // White fading overlay on top of the background image.
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withOpacity(0.8),
                                      Colors.white.withOpacity(0.4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Foreground content.
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Officer Name.
                                  Text(
                                    nearestOfficer["name"] ?? "Unknown",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange[700],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Tamil Name (if provided).
                                  if (nearestOfficer["tname"] != null &&
                                      nearestOfficer["tname"].isNotEmpty)
                                    Text(
                                      nearestOfficer["tname"],
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  // Tappable Contact Number with phone icon.
                                  GestureDetector(
                                    onTap: () => _makePhoneCall(
                                        nearestOfficer["contact"] ?? ""),
                                    child: Row(
                                      children: [
                                        Icon(Icons.phone,
                                            color: Colors.green, size: 28),
                                        const SizedBox(width: 10),
                                        Text(
                                          nearestOfficer["contact"] ??
                                              "Not Available",
                                          style: TextStyle(
                                            fontSize: 18,
                                            decoration: TextDecoration.underline,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Location Row.
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.location_on,
                                          color: Colors.redAccent, size: 28),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          nearestOfficer["location"] ??
                                              "Location not available",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Municipal Office Image with rounded corners.
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      nearestOfficer["imageUrl"] ?? "",
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                          Container(
                                            height: 180,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.broken_image,
                                                size: 100,
                                                color: Colors.grey[600]),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // New Section: Erode Collection Results.
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('erode')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation(
                                      Colors.green.shade700),
                                ),
                              );
                            }
                            // Filter results based on whether the description (text) contains the type(s).
                            List<DocumentSnapshot> filteredResults =
                            snapshot.data!.docs.where((doc) {
                              final type = doc.get('type');
                              bool isMatch = false;
                              if (type is List) {
                                for (var t in type) {
                                  if (text.contains(t)) {
                                    isMatch = true;
                                    break;
                                  }
                                }
                              } else if (type is String) {
                                if (text.contains(type)) {
                                  isMatch = true;
                                }
                              }
                              return isMatch;
                            }).toList();
                            if (filteredResults.isEmpty) {
                              return SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section Title.
                                Row(
                                  children: [
                                    Icon(FontAwesomeIcons.recycle,
                                        color: Colors.green.shade700, size: 30),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Relevant Disposal Measures:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                FutureBuilder<geo.Position>(
                                  future: _getUserLocation(), // Fetch the user's location.
                                  builder: (context, locSnapshot) {
                                    if (!locSnapshot.hasData) {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
                                        ),
                                      );
                                    }
                                    final userLatitude = locSnapshot.data!.latitude;
                                    final userLongitude = locSnapshot.data!.longitude;

                                    // Remove the fixed height container and use ListView with shrinkWrap and non-scrollable physics.
                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: filteredResults.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final result = filteredResults[index];
                                        // Get the latlong string from the document.
                                        final latlongStr = result.get('latlong');
                                        double distance = 0.0;
                                        if (latlongStr != null && latlongStr.contains(',')) {
                                          List<String> parts = latlongStr.split(',');
                                          if (parts.length == 2) {
                                            double resultLat = double.tryParse(parts[0].trim()) ?? 0.0;
                                            double resultLon = double.tryParse(parts[1].trim()) ?? 0.0;
                                            // Compute the distance in kilometers.
                                            distance = calculateDistance(
                                              userLatitude,
                                              userLongitude,
                                              resultLat,
                                              resultLon,
                                            );
                                          }
                                        }
                                        String distanceStr = "${distance.toStringAsFixed(1)} km away";
                                        return InkWell(
                                          onTap: () => _onCardTap(context, result),
                                          child: Card(
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            shadowColor: Colors.green.shade100,
                                            // The card itself now wraps a Container with a background image.
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(15),
                                                image: DecorationImage(
                                                  image: AssetImage('lib/assets/ease.jpg'),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              // Add an overlay container for the white fading effect.
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(15),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withOpacity(0.9),
                                                      Colors.white.withOpacity(0.11),
                                                      Colors.white.withOpacity(0.7),
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Left: Image with rounded corners.
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: Container(
                                                        width: 80,
                                                        height: 80,
                                                        child: (result.data() as Map<String, dynamic>).containsKey('image') && result.get('image') != null && result.get('image').toString().isNotEmpty
                                                            ? Image.network(
                                                                result.get('image'),
                                                                fit: BoxFit.cover,
                                                              )
                                                            : Container(
                                                                color: Colors.grey[300],
                                                                child: Icon(Icons.broken_image, size: 40, color: Colors.grey[600]),
                                                              ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Right: Text information.
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          // Name with maxLines set to 2 and ellipsis overflow.
                                                          Text(
                                                            result.get('name'),
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 18,
                                                              color: Colors.green.shade800,
                                                            ),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            result.get('address'),
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors.grey[700],
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.location_on,
                                                                size: 16,
                                                                color: Colors.green.shade600,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                distanceStr,
                                                                style: TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors.grey[600],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Optional arrow icon.
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 16,
                                                      color: Colors.green.shade600,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedFABColumn(
        onMapPressed: () => _openGoogleMaps(context),
        onReportPressed: () => _sendReportViaWhatsApp(context),
        onComplaintPressed: () => _raiseComplaint(context,image,FirebaseAuth.instance.currentUser!.uid,category),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class AnimatedFABColumn extends StatefulWidget {
  final VoidCallback onMapPressed;
  final VoidCallback onReportPressed;
  final VoidCallback onComplaintPressed;

  const AnimatedFABColumn({
    Key? key,
    required this.onMapPressed,
    required this.onReportPressed,
    required this.onComplaintPressed,
  }) : super(key: key);

  @override
  _AnimatedFABColumnState createState() => _AnimatedFABColumnState();
}

class _AnimatedFABColumnState extends State<AnimatedFABColumn> {
  double _mapScale = 1.0;
  double _reportScale = 1.0;
  double _complaintScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end, // Align buttons to the right
            children: [
              // "View on Map" Button
              GestureDetector(
                onTapDown: (_) => setState(() => _mapScale = 0.95),
                onTapUp: (_) {
                  setState(() => _mapScale = 1.0);
                  widget.onMapPressed();
                },
                onTapCancel: () => setState(() => _mapScale = 1.0),
                child: AnimatedScale(
                  scale: _mapScale,
                  duration: const Duration(milliseconds: 100),
                  child: FloatingActionButton.extended(
                    onPressed: widget.onMapPressed,
                    backgroundColor: Colors.orangeAccent,
                    elevation: 6,
                    icon: const Icon(Icons.map, color: Colors.white),
                    label: Text(
                      AppLocalizations.of(context)!.viewOnMap,
                      style: const TextStyle(color: Colors.white),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // "Report" Button
              GestureDetector(
                onTapDown: (_) => setState(() => _reportScale = 0.95),
                onTapUp: (_) {
                  setState(() => _reportScale = 1.0);
                  widget.onReportPressed();
                },
                onTapCancel: () => setState(() => _reportScale = 1.0),
                child: AnimatedScale(
                  scale: _reportScale,
                  duration: const Duration(milliseconds: 100),
                  child: FloatingActionButton.extended(
                    onPressed: widget.onReportPressed,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    label: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.lightBlueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.5),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Container(
                        constraints:
                        const BoxConstraints(minWidth: 140, minHeight: 48),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.report, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.report,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // "Clean" Button (Raise Complaint)
              GestureDetector(
                onTapDown: (_) => setState(() => _complaintScale = 0.95),
                onTapUp: (_) {
                  setState(() => _complaintScale = 1.0);
                  widget.onComplaintPressed();
                },
                onTapCancel: () => setState(() => _complaintScale = 1.0),
                child: AnimatedScale(
                  scale: _complaintScale,
                  duration: const Duration(milliseconds: 100),
                  child: FloatingActionButton.extended(
                    onPressed: widget.onComplaintPressed,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    label: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.deepOrangeAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.5),
                            offset: const Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Container(
                        constraints:
                        const BoxConstraints(minWidth: 160, minHeight: 48),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.cleaning_services, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Clean",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
      ),
    );
  }
}
