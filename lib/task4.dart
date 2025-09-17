import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecyclingSortingGameScreen extends StatefulWidget {
  @override
  _RecyclingSortingGameScreenState createState() =>
      _RecyclingSortingGameScreenState();
}

class _RecyclingSortingGameScreenState
    extends State<RecyclingSortingGameScreen> with SingleTickerProviderStateMixin {
  int score = 0;
  bool _isSubmitting = false;
  bool _isAutoSubmitted = false; // New flag to trigger auto submission

  List<Map<String, dynamic>> wasteItems = [
    {
      "name": "Banana Peel",
      "type": "Bio-Degradable",
      "image": "lib/assets/banana.png"
    },
    {
      "name": "Plastic Bottle",
      "type": "Non Bio-Degradable",
      "image": "lib/assets/plasticbottle.png"
    },
    {
      "name": "Paper",
      "type": "Bio-Degradable",
      "image": "lib/assets/paper.png"
    },
    {
      "name": "Glass Bottle",
      "type": "Non Bio-Degradable",
      "image": "lib/assets/glass.png"
    },
  ];

  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Method used for manual submission (if needed before score reaches 40)
  void _submitScore() async {
    setState(() {
      _isSubmitting = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in.")),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    await FirebaseFirestore.instance.collection("verify").add({
      "userId": currentUser.uid,
      "level": 4,
      "status": "Confirmed",
      "score": score,
      "timestamp": DateTime.now(),
      "description": "Recycling Sorting Game submission",
    });

    setState(() {
      _isSubmitting = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Submission Received",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.green.shade700)),
        content: Text("Your Recycling Sorting Game submission is saved.",
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
            Text("OK", style: TextStyle(color: Colors.green.shade700)),
          ),
        ],
      ),
    );
  }

  // Automatically store data and navigate back after 6 seconds.
  Future<void> _autoSubmitScore() async {
    setState(() {
      _isAutoSubmitted = true;
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("verify").add({
      "userId": currentUser.uid,
      "level": 4,
      "status": "Confirmed",
      "score": score,
      "timestamp": DateTime.now(),
      "description": "Recycling Sorting Game submission",
    });

    // After 6 seconds, automatically navigate back.
    Future.delayed(Duration(seconds: 6), () {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Trigger auto-submission once the score reaches 40
    if (score >= 40 && !_isAutoSubmitted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSubmitScore();
      });
    }

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Recycling Sorting Game",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 23,
          ),
        ),
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(
            Icons.recycling,
            color: Colors.white,
          ),
        ),
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco, color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Join the Green Revolution!",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 6,
                  duration: Duration(seconds: 3),
                  action: SnackBarAction(
                    label: "Join Now",
                    onPressed: () {
                      // Add join logic here.
                    },
                    textColor: Colors.green,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image.
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/ease.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // White fading overlay.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.6),
                  Colors.white.withOpacity(0.6),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10),
                // Score display in a Chip.
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.emoji_events,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                    label: Text(
                      "Score: $score",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    elevation: 4,
                    shadowColor: Colors.black38,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: Colors.greenAccent.withOpacity(0.7),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: wasteItems.length,
                    itemBuilder: (context, index) {
                      return Draggable<Map<String, dynamic>>(
                        data: wasteItems[index],
                        feedback: Material(
                          type: MaterialType.transparency,
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Transform.scale(
                              scale: 0.7,
                              child: _buildWasteItem(wasteItems[index],
                                  opacity: 0.8),
                            ),
                          ),
                        ),
                        childWhenDragging: _buildWasteItem(wasteItems[index],
                            opacity: 0.3),
                        child: _buildWasteItem(wasteItems[index]),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDragTarget("Bio-Degradable", Colors.teal),
                      _buildDragTarget("Non Bio-Degradable", Colors.deepOrange),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Only show the submit button if score is less than 40.
              ],
            ),
          ),
          // Win screen overlay: displayed when score is 40 or above.
          if (score >= 40)
            Container(
              color: Colors.white.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('lib/assets/earth.gif'),
                    SizedBox(height: 16),
                    Text(
                      "Thank you for Saving me!",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDragTarget(String title, Color color) {
    return DragTarget<Map<String, dynamic>>(
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: Duration(milliseconds: 250),
          width: 120,
          height: 150,
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isHovering ? color.withOpacity(0.85) : color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: isHovering ? 10 : 6,
                offset: Offset(0, isHovering ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  color: isHovering ? Colors.grey[700] : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
        );
      },
      onWillAccept: (data) => data!["type"] == title,
      onAccept: (data) {
        setState(() {
          score += 10;
          wasteItems.removeWhere((item) => item["name"] == data["name"]);
        });
      },
    );
  }

  // Updated waste item widget with a transparent background.
  Widget _buildWasteItem(Map<String, dynamic> item, {double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            item['image'],
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
