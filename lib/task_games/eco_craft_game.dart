import 'package:flutter/material.dart';
import 'dart:math';

class EcoCraftGame extends StatefulWidget {
  final VoidCallback? onComplete;
  EcoCraftGame({this.onComplete});
  @override
  _EcoCraftGameState createState() => _EcoCraftGameState();
}

class _EcoCraftGameState extends State<EcoCraftGame>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  List<CraftMaterial> materials = [];
  List<CraftMaterial> selectedMaterials = [];
  String? currentProject;
  int projectsCompleted = 0;
  bool gameCompleted = false;

  final Map<String, List<String>> craftProjects = {
    "Bird Feeder": ["🥤", "🌾", "🪢"],
    "Flower Pot": ["🥫", "🎨", "🌱"],
    "Pencil Holder": ["📦", "🎨", "✂️"],
    "Wind Chime": ["🥤", "🪢", "🔔"],
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateMaterials();
    _selectRandomProject();
  }

  void _initializeAnimations() {
    _sparkleController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  void _generateMaterials() {
    final allMaterials = ["🥤", "🥫", "📦", "🎨", "✂️", "🪢", "🌾", "🌱", "🔔"];
    final random = Random();

    for (int i = 0; i < 9; i++) {
      materials.add(CraftMaterial(
        id: i,
        emoji: allMaterials[i],
        x: 50.0 + (i % 3) * 100,
        y: 400.0 + (i ~/ 3) * 80,
        isSelected: false,
      ));
    }
  }

  void _selectRandomProject() {
    final projects = craftProjects.keys.toList();
    currentProject = projects[Random().nextInt(projects.length)];
  }

  void _selectMaterial(int materialId) {
    setState(() {
      final material = materials.firstWhere((m) => m.id == materialId);
      if (!material.isSelected && selectedMaterials.length < 3) {
        material.isSelected = true;
        selectedMaterials.add(material);

        if (selectedMaterials.length == 3) {
          _checkProject();
        }
      }
    });
  }

  void _checkProject() {
    final requiredMaterials = craftProjects[currentProject!]!;
    final selectedEmojis = selectedMaterials.map((m) => m.emoji).toList();

    bool isCorrect = requiredMaterials
        .every((material) => selectedEmojis.contains(material));

    if (isCorrect) {
      _completeProject();
    } else {
      _resetSelection();
    }
  }

  void _completeProject() {
    setState(() {
      projectsCompleted++;
      selectedMaterials.clear();

      // Reset materials
      for (var material in materials) {
        material.isSelected = false;
      }

      if (projectsCompleted >= 3) {
        _completeGame();
      } else {
        _selectRandomProject();
      }
    });
  }

  void _resetSelection() {
    setState(() {
      for (var material in selectedMaterials) {
        material.isSelected = false;
      }
      selectedMaterials.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Try again! Check the recipe carefully."),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
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
        title: Text("🎨 Eco Artist!", style: TextStyle(color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Amazing creativity! You made $projectsCompleted eco-crafts!",
                style: TextStyle(color: Colors.black)),
            SizedBox(height: 10),
            Text("You turned trash into treasure! ♻️",
                style: TextStyle(color: Colors.black)),
            Text("Keep being creative and eco-friendly! 🌍",
                style: TextStyle(color: Colors.black)),
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
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
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
              Color(0xFFF3E5F5),
              Color(0xFFE1BEE7),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Sparkle effects
            AnimatedBuilder(
              animation: _sparkleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SparklePainter(_sparkleController.value),
                  size: Size.infinite,
                );
              },
            ),

            // Game content
            Column(
              children: [
                _buildHeader(),
                _buildProjectDisplay(),
                _buildSelectedMaterials(),
                _buildMaterialsGrid(),
                _buildInstructions(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🎨 Eco Craft Studio",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[800],
                ),
              ),
              Text(
                "Projects: $projectsCompleted/3",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.purple[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDisplay() {
    if (currentProject == null) return Container();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Make a $currentProject",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple[800],
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Recipe:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: craftProjects[currentProject!]!
                .map(
                  (material) => Container(
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(material, style: TextStyle(fontSize: 30)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMaterials() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Column(
        children: [
          Text(
            "Selected Materials:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber[300]!),
                  ),
                  child: Center(
                    child: Text(
                      i < selectedMaterials.length
                          ? selectedMaterials[i].emoji
                          : "?",
                      style: TextStyle(fontSize: 30),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsGrid() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(20),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final material = materials[index];
            return GestureDetector(
              onTap: () => _selectMaterial(material.id),
              child: Container(
                decoration: BoxDecoration(
                  color: material.isSelected ? Colors.green[100] : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color:
                        material.isSelected ? Colors.green : Colors.grey[300]!,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    material.emoji,
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "🎯 Select 3 materials to match the recipe!\nTurn waste into wonderful crafts! ♻️",
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SparklePainter extends CustomPainter {
  final double animationValue;

  SparklePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 15; i++) {
      final x = (size.width * (i / 15) + animationValue * 100) % size.width;
      final y = (size.height * ((i * 0.7) % 1) +
              sin(animationValue * 2 * pi + i) * 50) %
          size.height;

      canvas.drawCircle(Offset(x, y), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CraftMaterial {
  final int id;
  final String emoji;
  final double x;
  final double y;
  bool isSelected;

  CraftMaterial({
    required this.id,
    required this.emoji,
    required this.x,
    required this.y,
    required this.isSelected,
  });
}
