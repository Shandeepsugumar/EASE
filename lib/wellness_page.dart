import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'image_result_page.dart';

class WellnessPage extends StatefulWidget {
  @override
  _WellnessPageState createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage> {
  File? _selectedImage;
  String? _imageDescription;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // Show a dialog to let the user choose
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          backgroundColor: Colors.green[50],
          title: Text(
            "Choose Image Source",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.green[800],
            ),
          ),
          content: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade200, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: Colors.green[700]),
                  title: Text(
                    "Camera",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[900],
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                  hoverColor: Colors.green[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                Divider(color: Colors.green[300], thickness: 1),
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.green[700]),
                  title: Text(
                    "Gallery",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[900],
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                  hoverColor: Colors.green[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return; // If user cancels the dialog

    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageDescription = null;
        _isLoading = true; // Set loading state
      });

      // Wait for the frame to render the loading indicator
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _fetchImageDescription(_selectedImage!);
      });
    }
  }

  Future<void> _fetchImageDescription(File image) async {
  setState(() => _isLoading = true);
  try {
    var url = Uri.parse("https://SanmathiSethu06-ObjectDetectionAPI.hf.space/detect");
    var request = http.MultipartRequest("POST", url)
      ..files.add(await http.MultipartFile.fromPath("image", image.path));
    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var data = jsonDecode(responseBody);
      final labelsRaw = data['labels'];
      final countRaw = data['count'];
      if (labelsRaw != null && labelsRaw is Map) {
        final labelsMap = Map<String, dynamic>.from(labelsRaw);

        // ✅ Extract detected labels
        final detectedLabels = labelsMap.keys.toList();

        // ✅ Build final map { "labels": ["Bottle", "Drink", "Food"] }
        final descriptionMap = {
          "labels": detectedLabels,
          "count": countRaw,
        };

        setState(() {
          _isLoading = false;
          _imageDescription = detectedLabels.isNotEmpty
              ? detectedLabels.join(", ")
              : "No objects detected.";
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageResultPage(
              image: image,
              descriptionText: descriptionMap, // 👈 Pass final map here
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _imageDescription = "No objects detected.";
        });
        _showUserMessage("No labels found, cannot fetch data.");
      }
    } else {
      setState(() => _isLoading = false);
      _showUserMessage("API Request failed.");
    }
  } catch (e) {
    setState(() => _isLoading = false);
    _showUserMessage("This may take a while. Please try again later.");
  }
}


  void _showUserMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep the same functionality
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.spa, color: Colors.white),
            SizedBox(width: 8),
            Text("Wellness & Environment",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green[900],
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: Stack(
        children: [
          // 1) Lightened background image from local asset
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/assets/ease.jpg'), // Replaced with local asset
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.7),
                    BlendMode.srcOver,
                  ),
                ),
              ),
            ),
          ),

          // 2) Loading overlay if needed
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loading GIF
                      Image.asset(
                        'lib/assets/loading.gif',
                        width: 120,
                        height: 120,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Analyzing Image...",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3) Main content (centered card)
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.only(top: kToolbarHeight + 40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      "Choose an Image",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Image Preview Container
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green[900]!.withOpacity(0.5), width: 3),
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.green[50],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _selectedImage == null
                            ? Icon(Icons.add_a_photo, size: 80, color: Colors.green[800])
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Button
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.upload, color: Colors.white),
                      label: Text("Select Image", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 6,
                      ),
                    ),
                    SizedBox(height: 20),

                    // If there's an image description from the API
                    if (_imageDescription != null)
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Text(
                          "🌱 Description: $_imageDescription",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),

                    // Motivational quote
                    SizedBox(height: 10),
                    Text(
                      "“The earth does not belong to us: we belong to the earth.” 🌍",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
