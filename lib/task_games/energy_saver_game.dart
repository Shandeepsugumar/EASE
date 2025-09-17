import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class EnergySaverGame extends StatefulWidget {
  final VoidCallback? onComplete;
  EnergySaverGame({this.onComplete});
  @override
  _EnergySaverGameState createState() => _EnergySaverGameState();
}

class _EnergySaverGameState extends State<EnergySaverGame>
    with TickerProviderStateMixin {
  late AnimationController _lightController;
  List<Appliance> appliances = [];
  int energySaved = 0;
  int appliancesTurnedOff = 0;
  bool gameCompleted = false;
  Timer? energyTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateAppliances();
    _startEnergyTimer();
  }

  void _initializeAnimations() {
    _lightController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _generateAppliances() {
    appliances = [
      Appliance(
        id: 1,
        name: "TV",
        emoji: "📺",
        x: 80,
        y: 200,
        isOn: true,
        energyUsage: 15,
      ),
      Appliance(
        id: 2,
        name: "Light",
        emoji: "💡",
        x: 200,
        y: 150,
        isOn: true,
        energyUsage: 10,
      ),
      Appliance(
        id: 3,
        name: "Fan",
        emoji: "🌀",
        x: 300,
        y: 180,
        isOn: true,
        energyUsage: 12,
      ),
      Appliance(
        id: 4,
        name: "Computer",
        emoji: "💻",
        x: 120,
        y: 350,
        isOn: true,
        energyUsage: 20,
      ),
      Appliance(
        id: 5,
        name: "AC",
        emoji: "❄️",
        x: 280,
        y: 320,
        isOn: true,
        energyUsage: 25,
      ),
      Appliance(
        id: 6,
        name: "Radio",
        emoji: "📻",
        x: 50,
        y: 450,
        isOn: true,
        energyUsage: 8,
      ),
    ];
  }

  void _startEnergyTimer() {
    energyTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (appliancesTurnedOff >= 5) {
        _completeGame();
        timer.cancel();
      }
    });
  }

  void _toggleAppliance(int applianceId) {
    setState(() {
      final appliance = appliances.firstWhere((a) => a.id == applianceId);
      if (appliance.isOn) {
        appliance.isOn = false;
        energySaved += appliance.energyUsage;
        appliancesTurnedOff++;
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
        title: Text("⚡ Energy Hero!", style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Amazing! You saved so much energy!", style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text("Energy Saved: ${energySaved}W ⚡", style: TextStyle(color: Colors.black)),
            Text("You're helping fight climate change! 🌍", style: TextStyle(color: Colors.black)),
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
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _lightController.dispose();
    energyTimer?.cancel();
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
              Color(0xFFFFF8E1),
              Color(0xFFFFE0B2),
            ],
          ),
        ),
        child: Stack(
          children: [
            // House background
            _buildHouseBackground(),
            
            // Appliances
            ...appliances.map((appliance) => Positioned(
              left: appliance.x,
              top: appliance.y,
              child: GestureDetector(
                onTap: () => _toggleAppliance(appliance.id),
                child: _buildApplianceWidget(appliance),
              ),
            )),
            
            // UI
            _buildGameUI(),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHouseBackground() {
    return CustomPaint(
      painter: HousePainter(),
      size: Size.infinite,
    );
  }

  Widget _buildApplianceWidget(Appliance appliance) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: appliance.isOn 
            ? Colors.yellow.withOpacity(0.3)
            : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: appliance.isOn ? Colors.yellow : Colors.grey,
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              appliance.emoji,
              style: TextStyle(fontSize: 40),
            ),
          ),
          if (appliance.isOn)
            Positioned(
              top: 5,
              right: 5,
              child: AnimatedBuilder(
                animation: _lightController,
                builder: (context, child) {
                  return Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(_lightController.value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ),
          Positioned(
            bottom: 5,
            left: 5,
            right: 5,
            child: Text(
              "${appliance.energyUsage}W",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: appliance.isOn ? Colors.red : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
                  "⚡ Energy Detective",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                  ),
                ),
                Text("Saved: ${energySaved}W"),
              ],
            ),
            Column(
              children: [
                Text(
                  "Turned Off: $appliancesTurnedOff/5",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "🎯 Tap on appliances with red lights to turn them off!\nSave energy and help the environment! 🌍",
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
}

class HousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown[300]!
      ..style = PaintingStyle.fill;

    // Draw house walls
    final houseRect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.3,
      size.width * 0.8,
      size.height * 0.6,
    );
    canvas.drawRect(houseRect, paint);

    // Draw roof
    final roofPaint = Paint()..color = Colors.red[800]!;
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.05, size.height * 0.3);
    roofPath.lineTo(size.width * 0.5, size.height * 0.15);
    roofPath.lineTo(size.width * 0.95, size.height * 0.3);
    roofPath.close();
    canvas.drawPath(roofPath, roofPaint);

    // Draw windows
    final windowPaint = Paint()..color = Colors.lightBlue[200]!;
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.4, 60, 60),
      windowPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.75, size.height * 0.4, 60, 60),
      windowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Appliance {
  final int id;
  final String name;
  final String emoji;
  final double x;
  final double y;
  bool isOn;
  final int energyUsage;

  Appliance({
    required this.id,
    required this.name,
    required this.emoji,
    required this.x,
    required this.y,
    required this.isOn,
    required this.energyUsage,
  });
}