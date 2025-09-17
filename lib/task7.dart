import 'package:flutter/material.dart';
class BeachCleanupGame extends StatefulWidget {
  @override
  _BeachCleanupGameState createState() => _BeachCleanupGameState();
}

class _BeachCleanupGameState extends State<BeachCleanupGame> {
  int score = 0;
  String? carryingTrash; // The trash item currently held by the player

  Map<String, String> trashToBin = {
    "plastic_bottle": "Plastic",
    "can": "Metal",
    "banana_peel": "Organic",
  };

  Map<String, bool> collected = {
    "plastic_bottle": false,
    "can": false,
    "banana_peel": false,
  };

  void checkDrop(String bin) {
    setState(() {
      if (carryingTrash != null && trashToBin[carryingTrash] == bin) {
        score += 10;
        collected[carryingTrash!] = true; // Mark as collected
        carryingTrash = null; // Player is no longer holding trash
      } else {
        score -= 5;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            // Beach Background
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("lib/assets/sea.jpg"), // Background image
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Display Score at the top
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                "Score: $score",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Draggable Trash Items
            if (!collected["plastic_bottle"]!)
              TrashItem(image: "lib/assets/plasticbottle.png", itemKey: "plastic_bottle", onPicked: (item) {
                setState(() => carryingTrash = item);
              }),
            if (!collected["can"]!)
              TrashItem(image: "lib/assets/glass.png", itemKey: "can", onPicked: (item) {
                setState(() => carryingTrash = item);
              }),
            if (!collected["banana_peel"]!)
              TrashItem(image: "lib/assets/banana.png", itemKey: "banana_peel", onPicked: (item) {
                setState(() => carryingTrash = item);
              }),

            // Drop Zones (Bins)
            Positioned(
              bottom: 50,
              left: 20,
              child: DragTarget<String>(
                onAccept: (trash) => checkDrop("Plastic"),
                builder: (context, candidateData, rejectedData) => BinWidget(
                  label: "Plastic",
                  binColor: Colors.blue,
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: 140,
              child: DragTarget<String>(
                onAccept: (trash) => checkDrop("Metal"),
                builder: (context, candidateData, rejectedData) => BinWidget(
                  label: "Metal",
                  binColor: Colors.grey,
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              right: 20,
              child: DragTarget<String>(
                onAccept: (trash) => checkDrop("Organic"),
                builder: (context, candidateData, rejectedData) => BinWidget(
                  label: "Organic",
                  binColor: Colors.green,
                ),
              ),
            ),

            // Show Stars Based on Score
            Positioned(
              top: 80,
              left: 20,
              child: StarDisplay(score: score),
            ),

            // **Player Character (Movable)**
            Positioned(
              bottom: 20,
              left: 150,
              child: Draggable<String>(
                data: carryingTrash,
                feedback: carryingTrash != null
                    ? Image.asset(carryingTrashToImage(carryingTrash!), width: 60, height: 60)
                    : Image.asset("lib/assets/standboy.png", width: 80, height: 80),
                childWhenDragging: Container(),
                child: Image.asset("lib/assets/standboy.png", width: 80, height: 80),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String carryingTrashToImage(String trash) {
    switch (trash) {
      case "plastic_bottle":
        return "lib/assets/plasticbottle.png";
      case "can":
        return "lib/assets/can.png";
      case "banana_peel":
        return "lib/assets/banana.png";
      default:
        return "lib/assets/player.png";
    }
  }
}

// Trash Item Widget
class TrashItem extends StatelessWidget {
  final String image;
  final String itemKey;
  final Function(String) onPicked;

  TrashItem({required this.image, required this.itemKey, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 150,
      left: (itemKey == "plastic_bottle") ? 50 : (itemKey == "can") ? 150 : 250,
      child: GestureDetector(
        onTap: () => onPicked(itemKey),
        child: Image.asset(image, width: 60, height: 60),
      ),
    );
  }
}

// Bin Widget
class BinWidget extends StatelessWidget {
  final String label;
  final Color binColor;

  BinWidget({required this.label, required this.binColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: binColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Star Display Widget
class StarDisplay extends StatelessWidget {
  final int score;

  StarDisplay({required this.score});

  int getStarCount() {
    if (score >= 30) return 3;
    if (score >= 20) return 2;
    if (score >= 10) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    int stars = getStarCount();
    return Row(
      children: List.generate(
        3,
            (index) => Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: Colors.yellow,
          size: 30,
        ),
      ),
    );
  }
}
