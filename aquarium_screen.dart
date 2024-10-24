import 'package:flutter/material.dart';
import 'dart:math';
import 'database_helper.dart';

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with TickerProviderStateMixin {
  List<Fish> _fishList = [];
  Color _selectedFishColor = Colors.blue;
  double _fishSpeed = 1.0;
  int _fishCount = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const int maxFishCount = 10; // Maximum number of fish
  bool _collisionEffectsEnabled = true; // Toggle for collision effects

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Load settings when the app starts
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getSettings();
    if (settings != null) {
      setState(() {
        _fishCount = settings['fishCount'];
        _fishSpeed = settings['fishSpeed'];
        _selectedFishColor = _getValidatedColor(settings['fishColor']);
        _fishList = List.generate(
          _fishCount,
          (index) => Fish(
            x: Random().nextDouble() * 280,
            y: Random().nextDouble() * 280,
            color: _selectedFishColor,
            speed: _fishSpeed,
            controller: AnimationController(
              vsync: this,
              duration: Duration(seconds: 5),
            )..repeat(),
          ),
        );
      });
    }
  }

  Color _getValidatedColor(int colorValue) {
    List<Color> validColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow
    ];
    Color loadedColor = Color(colorValue);

    if (!validColors.contains(loadedColor)) {
      return Colors.blue; // fallback color
    }
    return loadedColor;
  }

  Future<void> _saveSettings() async {
    await _dbHelper.saveSettings(
        _fishList.length, _fishSpeed, _selectedFishColor.value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  void _addFish() {
    if (_fishList.length >= maxFishCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum of $maxFishCount fish allowed!')),
      );
      return;
    }

    setState(() {
      _fishList.add(Fish(
        x: Random().nextDouble() * 280,
        y: Random().nextDouble() * 280,
        color: _selectedFishColor,
        speed: _fishSpeed,
        controller: AnimationController(
          vsync: this,
          duration: Duration(seconds: 5),
        )..repeat(),
      ));
    });
  }

  void _removeFish() {
    if (_fishList.isNotEmpty) {
      setState(() {
        _fishList.last.controller.dispose();
        _fishList.removeLast();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fish to remove!')),
      );
    }
  }

  @override
  void dispose() {
    for (var fish in _fishList) {
      fish.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aquarium'),
      ),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child: Stack(
              children: _fishList.map((fish) => _buildFish(fish)).toList(),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _addFish, child: Text('Add Fish')),
              SizedBox(width: 20),
              ElevatedButton(
                  onPressed: _removeFish, child: Text('Remove Fish')),
              SizedBox(width: 20),
              ElevatedButton(
                  onPressed: _saveSettings, child: Text('Save Settings')),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Collision Effects'),
              Switch(
                value: _collisionEffectsEnabled,
                onChanged: (value) {
                  setState(() {
                    _collisionEffectsEnabled = value;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 20),
          Text('Fish Speed: ${_fishSpeed.toStringAsFixed(1)}'),
          Slider(
            value: _fishSpeed,
            min: 0.5,
            max: 5.0,
            onChanged: (value) {
              setState(() {
                _fishSpeed = value;
                for (var fish in _fishList) {
                  fish.speed = value;
                }
              });
            },
          ),
          DropdownButton<Color>(
            value: _selectedFishColor,
            onChanged: (newColor) {
              setState(() {
                _selectedFishColor = newColor!;
              });
            },
            items: [
              DropdownMenuItem(
                  value: Colors.blue,
                  child: Text('Blue', style: TextStyle(color: Colors.blue))),
              DropdownMenuItem(
                  value: Colors.red,
                  child: Text('Red', style: TextStyle(color: Colors.red))),
              DropdownMenuItem(
                  value: Colors.green,
                  child: Text('Green', style: TextStyle(color: Colors.green))),
              DropdownMenuItem(
                  value: Colors.yellow,
                  child:
                      Text('Yellow', style: TextStyle(color: Colors.yellow))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFish(Fish fish) {
    return AnimatedBuilder(
      animation: fish.controller,
      builder: (context, child) {
        double deltaX = (Random().nextDouble() - 0.5) * fish.speed;
        double deltaY = (Random().nextDouble() - 0.5) * fish.speed;

        fish.x += deltaX;
        fish.y += deltaY;

        // Boundary check
        if (fish.x < 0 || fish.x > 280) {
          fish.x = fish.x < 0 ? 0 : 280;
        }
        if (fish.y < 0 || fish.y > 280) {
          fish.y = fish.y < 0 ? 0 : 280;
        }

        // Collision detection
        if (_collisionEffectsEnabled) {
          for (var otherFish in _fishList) {
            if (fish != otherFish && _isColliding(fish, otherFish)) {
              fish.color = _getRandomColor();
              fish.x -= deltaX * 2;
              fish.y -= deltaY * 2;
            }
          }
        }

        return Positioned(
          left: fish.x,
          top: fish.y,
          child: Container(
            width: fish.size,
            height: fish.size,
            decoration: BoxDecoration(
              color: fish.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  bool _isColliding(Fish fish1, Fish fish2) {
    double distance =
        sqrt(pow(fish1.x - fish2.x, 2) + pow(fish1.y - fish2.y, 2));
    return distance < (fish1.size / 2 + fish2.size / 2);
  }

  Color _getRandomColor() {
    List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.yellow];
    return colors[Random().nextInt(colors.length)];
  }
}

class Fish {
  double x;
  double y;
  Color color;
  double speed;
  AnimationController controller;
  double size = 20.0; // Default size

  Fish({
    required this.x,
    required this.y,
    required this.color,
    required this.speed,
    required this.controller,
  });
}
