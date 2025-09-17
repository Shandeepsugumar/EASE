import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class PlantGardenGame extends StatefulWidget {
  final VoidCallback? onComplete;
  PlantGardenGame({this.onComplete});
  @override
  _PlantGardenGameState createState() => _PlantGardenGameState();
}

class _PlantGardenGameState extends State<PlantGardenGame>
    with TickerProviderStateMixin {
  late AnimationController _sunController;
  late AnimationController _cloudController;
  List<PlantSlot> plantSlots = [];
  int waterLevel = 100;
  int seedsPlanted = 0;
  int plantsGrown = 0;
  bool gameCompleted = false;
  Timer? growthTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePlantSlots();
    _startGrowthTimer();
  }

  void _initializeAnimations() {
    _sunController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _cloudController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  void _initializePlantSlots() {
    for (int i = 0; i < 6; i++) {
      plantSlots.add(PlantSlot(
        id: i,
        x: 50.0 + (i % 3) * 100,
        y: 300.0 + (i ~/ 3) * 100,
        hasPlant: false,
        growthStage: 0,
        needsWater: false,
      ));
    }
  }

  void _startGrowthTimer() {
    growthTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        for (var slot in plantSlots) {
          if (slot.hasPlant && !slot.needsWater && slot.growthStage < 3) {
            if (Random().nextBool()) {
              slot.growthStage++;
              if (slot.growthStage == 3) {
                plantsGrown++;
              }
            } else {
              slot.needsWater = true;
            }
          }
        }
      });

      if (plantsGrown >= 4) {
        _completeGame();
        timer.cancel();
      }
    });
  }

  void _plantSeed(int slotId) {
    setState(() {
      final slot = plantSlots.firstWhere((s) => s.id == slotId);
      if (!slot.hasPlant) {
        slot.hasPlant = true;
        slot.growthStage = 1;
        seedsPlanted++;
      }
    });
  }

  void _waterPlant(int slotId) {
    setState(() {
      final slot = plantSlots.firstWhere((s) => s.id == slotId);
      if (slot.hasPlant && slot.needsWater && waterLevel > 0) {
        slot.needsWater = false;
        waterLevel -= 10;
      }
    });
  }

  void _completeGame() {
    setState(() {
      gameCompleted = true;
    });
    if (widget.onComplete != null) widget.onComplete!();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("🌻 Garden Master!", style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Your garden is blooming beautifully!", style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text("You grew $plantsGrown healthy plants! 🌱", style: TextStyle(color: Colors.black)),
            Text("You're helping make the world greener! 🌍", style: TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Continue Adventure"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sunController.dispose();
    _cloudController.dispose();
    growthTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF87CEEB),
              Color(0xFF98FB98),
              Color(0xFF228B22),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Sky elements
            _buildSkyElements(),
            
            // Garden area
            _buildGardenArea(),
            
            // UI
            _buildGameUI(),
            
            // Tools
            _buildTools(),
          ],
        ),
      ),
    );
  }

  Widget _buildSkyElements() {
    return Stack(
      children: [
        // Sun
        AnimatedBuilder(
          animation: _sunController,
          builder: (context, child) {
            return Positioned(
              top: 50 + sin(_sunController.value * 2 * pi) * 10,
              right: 50 + cos(_sunController.value * 2 * pi) * 5,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.yellow,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text("☀️", style: TextStyle(fontSize: 30)),
                ),
              ),
            );
          },
        ),
        
        // Clouds
        AnimatedBuilder(
          animation: _cloudController,
          builder: (context, child) {
            return Positioned(
              top: 80,
              left: 100 + _cloudController.value * 200,
              child: Text("☁️", style: TextStyle(fontSize: 40)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGardenArea() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 300,
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF8B4513),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Stack(
          children: plantSlots.map((slot) => Positioned(
            left: slot.x,
            top: slot.y - 250,
            child: GestureDetector(
              onTap: () {
                if (!slot.hasPlant) {
                  _plantSeed(slot.id);
                } else if (slot.needsWater) {
                  _waterPlant(slot.id);
                }
              },
              child: _buildPlantSlot(slot),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildPlantSlot(PlantSlot slot) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Color(0xFF654321),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.brown[800]!, width: 2),
      ),
      child: Center(
        child: slot.hasPlant
            ? Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    _getPlantEmoji(slot.growthStage),
                    style: TextStyle(fontSize: 35),
                  ),
                  if (slot.needsWater)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Text("💧", style: TextStyle(fontSize: 20)),
                    ),
                ],
              )
            : Icon(
                Icons.add,
                color: Colors.brown[300],
                size: 30,
              ),
      ),
    );
  }

  Widget _buildGameUI() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🌱 Garden Progress",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                Text("Grown: $plantsGrown/4"),
              ],
            ),
            Column(
              children: [
                Text(
                  "💧 Water: $waterLevel%",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Container(
                  width: 100,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: waterLevel / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTools() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.brown.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "🎯 Tap empty spots to plant seeds!\n💧 Tap plants with water drops to water them!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _getPlantEmoji(int stage) {
    switch (stage) {
      case 1:
        return "🌱";
      case 2:
        return "🌿";
      case 3:
        return "🌻";
      default:
        return "";
    }
  }
}

class PlantSlot {
  final int id;
  final double x;
  final double y;
  bool hasPlant;
  int growthStage;
  bool needsWater;

  PlantSlot({
    required this.id,
    required this.x,
    required this.y,
    required this.hasPlant,
    required this.growthStage,
    required this.needsWater,
  });
}