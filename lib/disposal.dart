import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'help.dart';
class DisposalPage extends StatefulWidget {
  final String responseText;
  final File image;
  final int count;
  DisposalPage({required this.responseText, required this.image, required this.count});

  @override
  _DisposalPageState createState() => _DisposalPageState();
}

class _DisposalPageState extends State<DisposalPage> {
  final FlutterTts flutterTts = FlutterTts();
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  bool showTasks = false;
  late String description;
  late List<String> tasks;
  Map<String, bool> completedTasks = {};
  int totalScore = 0;
  int visibleLines = 4;
  late List<String> youtubeLinks;
  late String category;

  // Add your high-complexity labels here
  final List<String> highComplexityLabels = [
    "tin", "coke", "bottle", "steel", "can", "aluminum", "glass", "plastic", "electronics"
  ];

  late List<String> detectedLabels;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));

    // ✅ Extract description, tasks, and category
    Map<String, dynamic> extractedData = extractDescriptionAndTasks(widget.responseText);
    description = extractedData["description"];
    youtubeLinks = extractYouTubeLinks(description);
    tasks = extractedData["tasks"];
    category = extractedData["category"];

    // Try to extract detected labels from responseText (if present)
    detectedLabels = extractDetectedLabels(widget.responseText);

    for (var task in tasks) {
      completedTasks[task] = false;
    }
  }

  // Utility to extract detected labels from responseText (if present)
  List<String> extractDetectedLabels(String text) {
    // Try to find a line like: "labels: [Bottle, Drink, Food]"
    final RegExp reg = RegExp(r'labels\s*:\s*\[([^\]]+)\]', caseSensitive: false);
    final match = reg.firstMatch(text);
    if (match != null) {
      return match.group(1)!.split(',').map((e) => e.trim().toLowerCase()).toList();
    }
    return [];
  }

  bool get isHighComplexity {
    // If any detected label matches a high-complexity label, return true
    return detectedLabels.any((label) =>
      highComplexityLabels.any((complex) => label.contains(complex)));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pageController.dispose();
    flutterTts.stop();
    super.dispose();
  }
  void showMore() {
    setState(() {
      visibleLines += 4; // Increase the number of lines displayed
    });
  }
  void toggleTasks() {
    setState(() {
      showTasks = !showTasks;
    });
  }

  List<String> extractYouTubeLinks(String text) {
    // Define a map of keywords to lists of YouTube video URLs.
    Map<String, List<String>> keywordVideos = {
      'aluminum': [
        'https://www.youtube.com/shorts/4ZVpC1nfmzE',
        'https://www.youtube.com/watch?v=_ItLfaO_WY0',
        'https://www.youtube.com/watch?v=5XAFMEBiouQ',
      ],
      'paper': [
        'https://www.youtube.com/shorts/rOQpYiU8y1M',
        'https://www.youtube.com/shorts/rWF0YPzxwb8',
        'https://www.youtube.com/shorts/7uYcSRMb5xE',
        'https://www.youtube.com/watch?v=aaz4Qe6zYyU',
      ],
      'plastic': [
        'https://www.youtube.com/watch?v=oDLjsFGFj7g',
        'https://www.youtube.com/watch?v=MH22eO9QqeQ',
        'https://www.youtube.com/shorts/SkLw6nwNdkU',
      ],
      'electronics': [
        'https://www.youtube.com/shorts/6ETBBHBbnlQ',
        'https://www.youtube.com/shorts/wAt2ouYB7-E',
        'https://www.youtube.com/watch?v=v8JJCbfIlws',
        'https://www.youtube.com/watch?v=SCj0gsb1rMs',
      ],
      'medicine': [
        'https://www.youtube.com/shorts/f6T5mkb5aqY',
        'https://www.youtube.com/shorts/-F-JoKuByps',
        'https://www.youtube.com/watch?v=wglXULEH7nU',
        'https://www.youtube.com/shorts/t5DeVj4Gu-Q',
      ],
      'pens': [
        'https://www.youtube.com/shorts/7CTJNsBVjSI',
        'https://www.youtube.com/watch?v=FCOkPfUYjo8',
        'https://www.youtube.com/watch?v=OxUAJ0w-Lx8',
      ],
      'phone': [
        'https://www.youtube.com/watch?v=5gUc9EE_O1Q',
      ],
      'wood': [
        'https://www.youtube.com/watch?v=JBg1MJVHjss',
        'https://www.youtube.com/watch?v=ARnTE_mL2N0',
        'https://www.youtube.com/shorts/lt5g749k2pY',
      ],
      'cloth': [
        'https://www.youtube.com/watch?v=yLZgrSpCAVs',
        'https://www.youtube.com/watch?v=S67EG8ntlcM',
      ],
      'battery': [
        'https://www.youtube.com/watch?v=2VtQXudqz74',
        'https://www.youtube.com/watch?v=wgSNYCxKLhI',
        'https://www.youtube.com/watch?v=67NgHePUk1g',
      ],
      'glass': [
        'https://www.youtube.com/watch?v=mwVwFxA47ZU',
        'https://www.youtube.com/watch?v=HZDeAFpi-lo',
        'https://www.youtube.com/watch?v=n4vlGT9-Zng',
      ],
      'bottle': [
        'https://www.youtube.com/shorts/-JWhg_ZR6tU',
        'https://www.youtube.com/shorts/uYYZTMjE9pA',
        'https://www.youtube.com/shorts/tDGPp1aDAI4',
        'https://www.youtube.com/watch?v=E19QrSIWfQU',
      ],
      'headphones': [
        'https://www.youtube.com/watch?v=pKLpRWodplg',
      ],
      'keyboard': [
        'https://www.youtube.com/shorts/ts2AvEjsFJE',
      ],
      'tires': [
        'https://www.youtube.com/shorts/u_agQ_5uU_I',
        'https://www.youtube.com/watch?v=ACfnS2nubHU',
      ],
      'erasers': [
        'https://www.youtube.com/shorts/7SmO5LXMWu8',
        'https://www.youtube.com/shorts/NnVlmhk-EWI',
        'https://www.youtube.com/shorts/wasTBqEoABI',
      ],
      'table': [
        'https://www.youtube.com/shorts/cpZOsXwY_h8',
      ],
      'chair': [
        'https://www.youtube.com/shorts/QXjIiyjnBQQ',
        'https://www.youtube.com/shorts/Dg4tSRPme-Q',
        'https://www.youtube.com/shorts/ECPtM3gpHho',
      ],
      'default': [
        'https://www.youtube.com/watch?v=PZ6SgdHQw_g',
        'https://www.youtube.com/watch?v=8facy0nK8Lw',
      ],
    };

    // List to store matched video links.
    List<String> resultLinks = [];

    // Check if the text contains any keywords and collect the related videos.
    keywordVideos.forEach((keyword, links) {
      if (text.toLowerCase().contains(keyword.toLowerCase())) {
        resultLinks.addAll(links);
      }
    });

    // If rkeyword matches, return default videos.
    if (resultLinks.isEmpty) {
      return keywordVideos['default']!;
    }

    return resultLinks;
  }


  Future<Map<String, dynamic>?> _findNearestMunicipalOfficer(Position userPosition) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> allOffices = [];

    // List of documents to fetch data from
    List<String> documents = ["erode", "perundurai"];

    for (String doc in documents) {
      DocumentSnapshot snapshot = await firestore.collection("municipal_office").doc(doc).get();

      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey("municipal")) {
          List<dynamic> municipalList = data["municipal"];

          for (var office in municipalList) {
            allOffices.add(office as Map<String, dynamic>);
          }
        }
      }
    }

    // Find the nearest office
    double minDistance = double.infinity;
    Map<String, dynamic>? nearestOffice;

    for (var office in allOffices) {
      List<String> latLong = (office['latlong'] as String).split(',');
      double officeLat = double.parse(latLong[0]);
      double officeLong = double.parse(latLong[1]);

      double distance = _calculateDistance(
        userPosition.latitude,
        userPosition.longitude,
        officeLat,
        officeLong,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestOffice = office;
      }
    }

    return nearestOffice;
  }
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Radius of the Earth in km
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }


  Map<String, dynamic> extractDescriptionAndTasks(String text) {
    List<String> lines = text.split("\n");
    String description = "";
    List<String> tasks = [];
    bool isTaskSection = false;
    String category = "";

    for (String line in lines) {
      String lowerLine = line.toLowerCase().trim();

      // ✅ Extract Category from Description
      RegExp categoryRegex = RegExp(r"category of ([a-zA-Z\s]+)", caseSensitive: false);
      Match? match = categoryRegex.firstMatch(lowerLine);
      if (match != null) {
        category = match.group(1)?.trim() ?? "";
      }

      // ✅ Check for the start of task section
      if (lowerLine.contains("tasks to be taken:") ||
          lowerLine.contains("task to be taken:") ||
          lowerLine.contains("tasks to be taken") ||
          lowerLine.contains("here's what you need to do")) {
        isTaskSection = true;
        if (line.contains(":")) {
          String possibleTasks = line.split(":")[1].trim();
          if (possibleTasks.isNotEmpty) tasks.add(possibleTasks);
        }
        continue;
      }

      if (isTaskSection) {
        if (RegExp(r"^\d+\.$").hasMatch(line.trim())) {
          continue;
        }
        if (RegExp(r"^\d+\.\s").hasMatch(line) || // For numeric tasks (e.g., 1. Task)
            RegExp(r"^[IVXLCDM]+\.\s").hasMatch(line) || // For Roman numeral tasks
            RegExp(r"^[-•]\s").hasMatch(line)) { // For bullet points
          tasks.add(line.substring(2).trim());
        } else if (line.isNotEmpty) {
          tasks.add(line.trim());
        }
      } else {
        description += line + " ";
      }
    }

    return {
      "description": description.trim(),
      "tasks": tasks,
      "category": category.isNotEmpty ? category : "Unknown"
    };
  }

  int calculatePoints(String task) {
    List<String> eWasteItems = ["battery", "circuit", "mobile", "laptop", "chip"];
    int basePoints = eWasteItems.any((item) => task.toLowerCase().contains(item)) ? 30 : 10;
    // Multiply by count of detected items
    return basePoints * (widget.count > 0 ? widget.count : 1);
  }

  void markTaskComplete(String task) {
    setState(() {
      if (completedTasks[task]!) {
        // If task is already completed, deselect it and subtract points
        completedTasks[task] = false;
        totalScore -= calculatePoints(task);
      } else {
        // If task is not completed, mark it as complete and add points
        completedTasks[task] = true;
        totalScore += calculatePoints(task);
      }
    });
  }

  void handleCompletion() async {
    if (completedTasks.values.every((completed) => completed)) {
      if (isHighComplexity) {
        // Only for high-complexity products, ask for quantity and after-image
        await _storeCompletionData();
        _confettiController.play();
      } else {
        // For simple products, just show points and success
        await _storeSimpleCompletion();
        _confettiController.play();
        showSuccessDialog(context, totalScore);
      }
    } else {
      showIncompleteDialog(context);
    }
  }

  // For simple products, just update points and streak, no verification
  Future<void> _storeSimpleCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final lastCompletionTimestamp = data['lastTaskCompletion'];
        DateTime? lastCompletion;
        if (lastCompletionTimestamp != null && lastCompletionTimestamp is Timestamp) {
          lastCompletion = lastCompletionTimestamp.toDate();
        }
        final currentStreak = data['streakCount'] ?? 0;
        final now = DateTime.now();
        int updatedStreak = currentStreak;
        if (lastCompletion != null) {
          if (now.difference(lastCompletion).inDays == 1) {
            updatedStreak += 1;
          } else if (now.difference(lastCompletion).inDays > 1) {
            updatedStreak = 1;
          }
        } else {
          updatedStreak = 1;
        }
        await userDoc.update({
          'lastTaskCompletion': now,
          'streakCount': updatedStreak,
          'status': 'completed',
          'points': FieldValue.increment(totalScore),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Points added successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

// For converting image to bytes
  Future<void> _storeCompletionData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;

        // ✅ Get Last Completion Time
        final lastCompletionTimestamp = data['lastTaskCompletion'];
        DateTime? lastCompletion;

        if (lastCompletionTimestamp != null && lastCompletionTimestamp is Timestamp) {
          lastCompletion = lastCompletionTimestamp.toDate();
        }

        final currentStreak = data['streakCount'] ?? 0;
        final now = DateTime.now();

        int updatedStreak = currentStreak;

        // ✅ Streak Logic
        if (lastCompletion != null) {
          if (now.difference(lastCompletion).inDays == 1) {
            updatedStreak += 1; // Continue streak
          } else if (now.difference(lastCompletion).inDays > 1) {
            updatedStreak = 1; // Reset streak
          }
        } else {
          updatedStreak = 1; // First-time completion, start streak
        }

        // ✅ Convert Before Image to Base64
        String? base64BeforeImage;
        if (widget.image != null) {
          try {
            Uint8List uint8List = await widget.image!.readAsBytes(); // Read file as bytes
            base64BeforeImage = base64Encode(uint8List); // Encode to base64
          } catch (e) {
            print("Error encoding before image to base64: $e");
          }
        }

        // ✅ Fetch Quantity and After Image
        int? quantity = await _getQuantityFromUser();
        File? afterImageFile = await _pickImageFromUser();

        // ✅ Convert After Image to Base64
        String? base64AfterImage;
        if (afterImageFile != null) {
          try {
            Uint8List uint8List = await afterImageFile.readAsBytes();
            base64AfterImage = base64Encode(uint8List);
          } catch (e) {
            print("Error encoding after image to base64: $e");
          }
        }

        // ✅ Update Firestore
        await userDoc.update({
          'lastTaskCompletion': now,
          'streakCount': updatedStreak,
          'status': 'waiting',
          if (quantity != null) 'quantity': quantity,
          if (base64BeforeImage != null) 'beforeImage': base64BeforeImage,
          if (base64AfterImage != null) 'completedImage': base64AfterImage,
        });

        // ✅ Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completion data stored successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // ✅ Display "Task Under Verification" Message After Success
        Future.delayed(const Duration(seconds: 2), () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Your task is under verification! You can redeem points later. See Profile.'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        });
      }
    }
  }

// ✅ Method to get quantity from user
  Future<int?> _getQuantityFromUser() async {
    TextEditingController _quantityController = TextEditingController();

    return await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Quantity'),
        content: TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(_quantityController.text);
              if (quantity != null && quantity > 0) {
                Navigator.of(context).pop(quantity);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

// ✅ Method to pick after image from user
  Future<File?> _pickImageFromUser() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }


  void showIncompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red[800],
            borderRadius: BorderRadius.circular(100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(75),
                child: Image.network(
                  "https://cdn.dribbble.com/users/1993461/screenshots/8519252/media/1e383519e624dc7986f6af81745d2d0e.gif",
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Keep Going!",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "Save Earth with small actions!",
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSuccessDialog(BuildContext context, int totalScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[400],
            borderRadius: BorderRadius.circular(100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(75),
                child: Image.network(
                  "https://i.giphy.com/7bOnU4QwFgPa2Ta2HJ.webp",
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Great Job!",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                "You earned $totalScore points!",
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green[400],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Position> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error("Location permissions are permanently denied.");
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade900, Colors.green.shade500],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: SafeArea(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FontAwesomeIcons.recycle, color: Colors.white, size: 30),
                  SizedBox(width: 12),
                  Text(
                    "Disposal Measures",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Colors.black45,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
        body: Stack(
        children: [
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
                      Colors.white.withOpacity(0.7),
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
          Padding(
            padding: EdgeInsets.all(16),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.leaf, color: Colors.green[800], size: 28),
                      SizedBox(width: 10),
                      Text("Why is this Important?",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800])),
                      IconButton(
                        icon: Icon(Icons.volume_up, color: Colors.green[800], size: 28),
                        onPressed: () async {
                          // Optionally configure language and pitch:
                          await flutterTts.setLanguage("en-US");
                          await flutterTts.setPitch(1.0);
                          // Speak out the description text
                          await flutterTts.speak(description);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Description with dynamic "Read More"
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textSpan = TextSpan(
                        text: description,
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      );
                      final textPainter = TextPainter(
                        text: textSpan,
                        maxLines: visibleLines,
                        textDirection: TextDirection.ltr,
                      )..layout(maxWidth: constraints.maxWidth);

                      final isOverflowing = textPainter.didExceedMaxLines;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            description,
                            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                            maxLines: visibleLines,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isOverflowing) // Show Read More button if text is overflowing
                            TextButton(
                              onPressed: showMore,
                              child: Text(
                                "Read More",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 20),

                  if (youtubeLinks.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with title and icon
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(FontAwesomeIcons.youtube, color: Colors.redAccent, size: 30),
                              const SizedBox(width: 12),
                              Text(
                                "Watch & Learn",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black26,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Glassmorphic video container with enhanced styling
                        Container(
                          height: 300,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(2, 2),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Stack(
                                children: [
                                  // Video carousel using PageView.builder
                                  PageView.builder(
                                    controller: _pageController,
                                    itemCount: youtubeLinks.length,
                                    itemBuilder: (context, index) {
                                      String videoId = YoutubePlayer.convertUrlToId(youtubeLinks[index])!;
                                      return Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(24),
                                          child: YoutubePlayer(
                                            controller: YoutubePlayerController(
                                              initialVideoId: videoId,
                                              flags: const YoutubePlayerFlags(
                                                autoPlay: false,
                                                mute: false,
                                              ),
                                            ),
                                            showVideoProgressIndicator: true,
                                            progressIndicatorColor: Colors.redAccent,
                                          ),
                                        ),
                                      );
                                    },
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index;
                                      });
                                    },
                                  ),
                                  // Animated page indicator at the bottom center
                                  Positioned(
                                    bottom: 20,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(youtubeLinks.length, (index) {
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          margin: const EdgeInsets.symmetric(horizontal: 5),
                                          width: _currentPage == index ? 14 : 10,
                                          height: _currentPage == index ? 14 : 10,
                                          decoration: BoxDecoration(
                                            color: _currentPage == index ? Colors.redAccent : Colors.white70,
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                  // Header overlay with a title
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.6),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(28),
                                          topRight: Radius.circular(28),
                                        ),
                                      ),
                                      child: const Text(
                                        "Featured Videos",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Buttons row with improved padding and elevation
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  toggleTasks(); // This should show the tasks section
                                  Future.delayed(const Duration(milliseconds: 300), () {
                                    _scrollController.animateTo(
                                      _scrollController.position.maxScrollExtent,
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[800],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8,
                                ),
                                icon: const Icon(Icons.cleaning_services, size: 28),
                                label: const Text("Clean", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  Position userPosition = await _getUserLocation();
                                  Map<String, dynamic>? nearestOfficer = await _findNearestMunicipalOfficer(userPosition);

                                  if (nearestOfficer != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HelpPage(
                                          nearestOfficer: nearestOfficer,
                                          image: widget.image,
                                          text: description,
                                          category : category
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[800],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8,
                                ),
                                icon: const Icon(Icons.help_outline, size: 28),
                                label: const Text("Help", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ],


                  SizedBox(height: 20),

                  // Show tasks only if "Clean" is pressed
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: showTasks
                        ? Column(
                      children: [
                        Row(
                          children: [
                            Icon(FontAwesomeIcons.tasks, color: Colors.green[800], size: 28),
                            SizedBox(width: 10),
                            Text(
                              "Tasks to Complete",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[800]),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            String task = tasks[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: GestureDetector(
                                onTap: () => markTaskComplete(task),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 600),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    color: completedTasks[task]!
                                        ? Colors.greenAccent.withOpacity(0.7)
                                        : Colors.white.withOpacity(0.85),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      completedTasks[task]!
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: Colors.green[800],
                                      size: 26,
                                    ),
                                    title: Text(
                                      task,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[900]
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20,),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: handleCompletion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.95),
                              foregroundColor: Colors.green[900],
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              shadowColor: Colors.black45,
                              elevation: 5,
                            ),
                            icon: Icon(Icons.done, size: 24),
                            label: Text("Mark as Complete", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    )
                        : SizedBox.shrink(),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}