import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EcoFriendlyArtScreen extends StatefulWidget {
  const EcoFriendlyArtScreen({Key? key}) : super(key: key);

  @override
  _EcoFriendlyArtScreenState createState() => _EcoFriendlyArtScreenState();
}

class _EcoFriendlyArtScreenState extends State<EcoFriendlyArtScreen>
    with SingleTickerProviderStateMixin {
  bool _isVerifying = false;
  String _result = "";
  String _currentGif = 'lib/assets/eco.gif';

  final String _authorizationHeader =
      'Basic YWNjXzc0MDA2MTA5N2ZmYjNmNzozZjZlYWQwMzQ4NmQzOTgwZGY3NWQyNmYxZDg4YmVmMA==';

  // Animation controller for subtle transitions
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndVerifyImage() async {
    final picker = ImagePicker();
    final XFile? imageFile =
    await picker.pickImage(source: ImageSource.gallery);
    if (imageFile == null) return;
    setState(() {
      _isVerifying = true;
      _currentGif = 'lib/assets/eco.gif';
      _result = "";
    });
    bool isCraft = await verifyCraftWork(imageFile.path);
    if (isCraft) {
      await storeVerificationResult();
    }
    setState(() {
      _isVerifying = false;
      _result = isCraft ? "This is a craft work! 🎨" : "Not a craft work. ❌";
      _currentGif =
      isCraft ? 'lib/assets/success.gif' : 'lib/assets/fail.gif';
    });
    _animationController.forward(from: 0);
  }
  Future<void> storeVerificationResult() async {
    await FirebaseFirestore.instance.collection('verify').add({
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'level':5,
      'status': 'Confirmed',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> verifyCraftWork(String imagePath) async {
    var uploadUrl = Uri.parse('https://api.imagga.com/v2/uploads');
    var request = http.MultipartRequest('POST', uploadUrl);
    request.headers['Authorization'] = _authorizationHeader;
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    var uploadResponse = await request.send();
    if (uploadResponse.statusCode != 200) return false;

    var uploadResponseBody = await uploadResponse.stream.bytesToString();
    var uploadJson = json.decode(uploadResponseBody);
    String? uploadId = uploadJson['result']?['upload_id'];
    if (uploadId == null) return false;

    var tagsUrl =
    Uri.parse('https://api.imagga.com/v2/tags?image_upload_id=$uploadId');
    var tagsResponse =
    await http.get(tagsUrl, headers: {'Authorization': _authorizationHeader});
    if (tagsResponse.statusCode != 200) return false;

    var tagsJson = json.decode(tagsResponse.body);
    List<dynamic>? tags = tagsJson['result']?['tags'];
    if (tags == null) return false;

    List<String> craftKeywords = [
      'eco-friendly art',
      'recycled art',
      'upcycled art',
      'repurposed',
      'sustainable decor',
      'diy art',
      'creative reuse',
      'recyclable materials',
      'environmental art',
      'eco decor',
      'green',
      'art'
    ];

    for (var tagInfo in tags) {
      var tag = tagInfo['tag']?['en'];
      if (tag != null &&
          craftKeywords.any((keyword) => tag.toLowerCase().contains(keyword))) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Enhanced gradient for AppBar and background
    final appBarGradient = LinearGradient(
      colors: [Colors.green.shade800, Colors.green.shade600],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Eco-Friendly Art & Decor',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade800, Colors.green.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 6,
        shadowColor: Colors.greenAccent.shade400,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade200, Colors.green.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          // White fading background image
          image: DecorationImage(
            image: AssetImage('lib/assets/ease.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.8),
              BlendMode.softLight,
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header
                  Text(
                    'Eco-Friendly Art & Decor 🌱',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Full eco.gif display using AspectRatio for natural scaling
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      child: AspectRatio(
                        aspectRatio: 16 / 9, // Adjust if needed for your eco.gif
                        child: Image.asset(
                          _currentGif,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Gather recyclable materials like newspapers, bottle caps, or cardboard and create a unique piece of art for your home or community!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.green.shade800,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  // Upload Button with gradient background
                  _isVerifying
                      ? CircularProgressIndicator(color: Colors.green.shade700)
                      : Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade700,
                          Colors.green.shade500,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.shade200,
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickAndVerifyImage,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.upload_file, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Upload Your Art',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Inspiration Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eco Inspiration',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildInspirationCard('lib/assets/art1.jpg', 'Recycled Bottle Art'),
                            _buildInspirationCard('lib/assets/art2.jpg', 'Cardboard Sculptures'),
                            _buildInspirationCard('lib/assets/art3.jpg', 'Upcycled Fashion'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Why Go Eco-Friendly Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade400,
                          offset: const Offset(0, 4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Why Go Eco-Friendly?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildEcoIcon(Icons.eco, 'Sustainable'),
                            // Fixed the issue: replaced Icons.recycling with Icons.autorenew
                            _buildEcoIcon(Icons.autorenew, 'Recyclable'),
                            _buildEcoIcon(Icons.lightbulb, 'Innovative'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Result Display with animated opacity and scale transition
                  AnimatedOpacity(
                    opacity: _result.isNotEmpty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                _result,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: _result.contains('craft work')
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Image.asset(
                                _result.contains('craft work')
                                    ? 'lib/assets/success.gif'
                                    : 'lib/assets/fail.gif',
                                height: 80,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build an inspiration card
  Widget _buildInspirationCard(String imagePath, String title) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade400,
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Container(
        alignment: Alignment.bottomCenter,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.0),
              Colors.black.withOpacity(0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // Helper method to build eco-friendly icon with label
  Widget _buildEcoIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 40),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.green.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
