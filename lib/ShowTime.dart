import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class RecyclingSearchPage extends StatefulWidget {
  @override
  _RecyclingSearchPageState createState() => _RecyclingSearchPageState();
}

class _RecyclingSearchPageState extends State<RecyclingSearchPage> {
  String _currentAddress = "Fetching location...";
  double? _latitude, _longitude;
  bool _isLoadingLocation = true;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // Get User's Current Location
  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          setState(() {
            _currentAddress = "Location permission denied";
            _isLoadingLocation = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _latitude = position.latitude;
      _longitude = position.longitude;
      List<Placemark>? placemarks = await GeocodingPlatform.instance
          ?.placemarkFromCoordinates(_latitude!, _longitude!);
      Placemark? place = placemarks?.isNotEmpty == true ? placemarks![0] : null;
      setState(() {
        _currentAddress = '${place!.name}, ${place.locality}, ${place.country}';
        _isLoadingLocation = false;
      });

      _fetchPlaces();
    } catch (e) {
      setState(() {
        _currentAddress = "Location not available";
        _isLoadingLocation = false;
      });
    }
  }

  // Fetch Data from Firestore and Calculate Distance
  Future<void> _fetchPlaces() async {
    setState(() {
      _results.clear();
    });

    try {
      await Future.wait([
        _fetchCollection('erode'),
        _fetchCollection('perundurai'),
      ]);
    } catch (e) {
      print("Error fetching places: $e");
    }
  }

  // Fetch Collection and Process Documents
  Future<void> _fetchCollection(String collectionName) async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection(collectionName).get();
      for (var doc in snapshot.docs) {
        _processDocument(doc);
      }
    } catch (e) {
      print("Error fetching collection $collectionName: $e");
    }
  }

  // Process Document, Calculate Distance, and Add to Results
  void _processDocument(QueryDocumentSnapshot doc) {
    try {
      String latlong = doc['latlong'];
      List<String> latLongParts = latlong.split(',');
      double lat = double.parse(latLongParts[0]);
      double lon = double.parse(latLongParts[1]);

      double distance = _calculateDistance(lat, lon, _latitude!, _longitude!);

      // Avoid duplicates by name
      bool isDuplicate = _results.any((place) => place['name'] == doc['name']);
      if (!isDuplicate) {
        setState(() {
          _results.add({
            'name': doc['name'],
            'address': doc['address'],
            'lat': lat,
            'lon': lon,
            'distance': distance,
            'image': doc['image'],
            'phone': doc['phone'],
            'link': doc['link'],
            'type': doc['type'], // ✅ Added type variable
          });
          _results.sort((a, b) => a['distance'].compareTo(b['distance']));
        });
      }
    } catch (e) {
      print("Error processing document: $e");
    }
  }

  // Calculate Distance between User and Place
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371; // in km
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  double _degreesToRadians(double degree) {
    return degree * pi / 180.0;
  }

  // Navigate to Details Page
  void _onCardTap(Map<String, dynamic> placeData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          placeData: placeData,
          userLatitude: _latitude!,
          userLongitude: _longitude!,
        ),
      ),
    );
  }

  String _filterType = 'All'; // Default filter type

  @override
  Widget build(BuildContext context) {
    List filteredResults = _results.where((result) {
      bool isDegradable = false;

      // Handle both string and list cases for 'type'
      if (result['type'] is String) {
        isDegradable = result['type'].toLowerCase().contains('paper');
      } else if (result['type'] is List) {
        isDegradable =
            result['type'].any((item) => item.toLowerCase() == 'paper');
      }

      // Filter based on type and collection
      if (_filterType == 'Degradable') {
        return isDegradable;
      } else if (_filterType == 'Non-Biodegradable') {
        return !isDegradable;
      } else {
        return true; // Show all if no filter selected
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Recycling Centers & Junk Yards",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: 1.2,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.green.shade300,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.green.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, size: 28, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(
                      "Discover Hidden Gems!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    content: Text(
                      "Step into a world of eco-friendly wonders! Uncover recycling centers and junk yards that transform waste into treasure. Ready to explore?",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade600),
                    ),
                    actions: [
                      TextButton(
                        child: Text(
                          "Let's Explore!",
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                  );
                },
              );
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌍 Location Section
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green.shade700, size: 30),
                SizedBox(width: 10),
                Text(
                  "Your Location:",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green.shade700,
                      ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _isLoadingLocation
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
                    ),
                  )
                : Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        _currentAddress,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ),
            SizedBox(height: 20),
            // 🔽 Dropdown Filter
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.green.shade400,
                  width: 1.2,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _filterType,
                  icon: Icon(Icons.arrow_drop_down,
                      color: Colors.green.shade600, size: 28),
                  isExpanded: true,
                  dropdownColor: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                  items: ['All', 'Degradable', 'Non-Biodegradable']
                      .map((String value) => DropdownMenuItem(
                            value: value,
                            child: Row(
                              children: [
                                Icon(
                                  value == 'All'
                                      ? Icons.layers
                                      : value == 'Degradable'
                                          ? Icons.eco
                                          : Icons.delete,
                                  color: value == 'Degradable'
                                      ? Colors.green.shade600
                                      : value == 'Non-Biodegradable'
                                          ? Colors.red.shade400
                                          : Colors.blue.shade400,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  value,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _filterType = newValue!;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            // 🌟 Results Section
            Expanded(
              child: filteredResults.isEmpty
                  ? Center(
                      child: Text(
                        "No centers found for '$_filterType'.",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredResults.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final result = filteredResults[index];
                        double distance = result['distance'];
                        String distanceStr =
                            "${distance.toStringAsFixed(1)} km away";
                        return InkWell(
                          onTap: () => _onCardTap(result),
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: Theme.of(context).cardColor,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // 🖼️ Image Section
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      child: Image.network(
                                        result['image'],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  // 📝 Info Section
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          result['name'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          result['address'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white70
                                                    : Colors.black87,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 16,
                                                color: Colors.green.shade600),
                                            SizedBox(width: 4),
                                            Text(
                                              distanceStr,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 14,
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white70
                                                        : Colors.black54,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ➡️ Arrow Icon
                                  Icon(Icons.arrow_forward_ios,
                                      size: 16, color: Colors.green.shade600),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> placeData;
  final double userLatitude;
  final double userLongitude;

  DetailPage({
    required this.placeData,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  Widget build(BuildContext context) {
    // Extract recycling and accessibility data from placeData
    List<String> recyclingList =
        List<String>.from(placeData['recycling'] ?? []);
    String accessibility = placeData['accessibility'] ?? "N/A";

    // Calculate distance from the user
    double distance = _calculateDistance(
        placeData['lat'], placeData['lon'], userLatitude, userLongitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recycling Center Nearby',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.green.shade800,
        elevation: 0,
      ),
      // Stack to layer the background image with gradient and the content
      body: Stack(
        children: [
          // Background: local asset with a gradient overlay that starts white at the top
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
                      Colors.white,
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.6),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Content Area
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header image with rounded corners and fade overlay
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      Image.network(
                        placeData['image'],
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        height: 250,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black54,
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Title with modern Google Fonts
                Text(
                  placeData['name'],
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.green.shade800,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Divider(
                  thickness: 1,
                  color: Colors.green.shade100,
                ),
                SizedBox(height: 16),
                // Address Section
                _buildAddressSection(),
                SizedBox(height: 20),
                // Animated Distance Section
                _buildDistanceSection(distance),
                SizedBox(height: 20),
                // Phone Section (call-to-action)
                _buildPhoneSection(),
                SizedBox(height: 20),
                // Accessibility Section with soft frosted glass effect
                _buildAccessibilitySection(accessibility),
                SizedBox(height: 20),
                // Recycling Options Section
                _buildRecyclingOptionsSection(recyclingList),
                SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
      // Floating action button for launching link
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final link = placeData['link'];
          if (await canLaunch(link)) {
            await launch(link);
          } else {
            throw 'Could not launch $link';
          }
        },
        backgroundColor: Colors.green.shade800,
        child: Icon(
          Icons.location_on,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }

  // Address Section with icon
  Widget _buildAddressSection() {
    return Row(
      children: [
        Icon(Icons.location_on, color: Colors.green.shade700, size: 30),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            placeData['address'],
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Animated Distance Section with TweenAnimationBuilder
  Widget _buildDistanceSection(double distance) {
    final progressValue = (distance / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Distance from you:",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.green.shade800),
        ),
        SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progressValue),
          duration: Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.green.shade200, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 12,
                    valueColor: AlwaysStoppedAnimation(Colors.green.shade700),
                    backgroundColor: Colors.white.withOpacity(0.3),
                  ),
                ),
                Text(
                  "${distance.toStringAsFixed(2)} km",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Phone Section with call action wrapped in a Card
  Widget _buildPhoneSection() {
    String phone = placeData['phone'] ?? '';
    return GestureDetector(
      onTap: () async {
        if (phone.isNotEmpty) {
          final callUrl = 'tel:$phone';
          if (await canLaunch(callUrl)) {
            await launch(callUrl);
          } else {
            throw 'Could not launch $callUrl';
          }
        }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.phone, color: Colors.green.shade700, size: 30),
              SizedBox(width: 10),
              Text(
                "Phone: ${phone.isNotEmpty ? phone : 'N/A'}",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Accessibility Section with frosted glass effect
  Widget _buildAccessibilitySection(String accessibility) {
    return accessibility != "N/A"
        ? ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                padding: EdgeInsets.all(16),
                child: Text(
                  "Accessibility: $accessibility",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        : SizedBox.shrink();
  }

  // Recycling Options Section with updated sleek cards
  Widget _buildRecyclingOptionsSection(List<String> recyclingList) {
    return recyclingList.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Recycling Options:",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold),
              ),
              ...recyclingList.map((item) => Card(
                    color: Colors.green.shade50,
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        "- $item",
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                  )),
            ],
          )
        : SizedBox.shrink();
  }

  // Calculate distance between coordinates using Haversine formula
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371; // Earth radius in kilometers
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  // Convert degrees to radians
  double _degreesToRadians(double degree) {
    return degree * pi / 180.0;
  }
}
