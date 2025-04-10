import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../services/image_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import 'recognition_results.dart';
import '../generate_recipe_screen.dart';
import '../../../theme/colors.dart';

class ActionButton extends StatelessWidget {
  ActionButton({super.key});

  final ImageService _imageService = ImageService();

  Future<void> _pickImage(BuildContext context, String endpoint) async {
    final image = await _imageService.pickImage('camera');
    if (image != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final recognizedIngredients = await _imageService.processImage(image, endpoint);
        Navigator.of(context).pop(); // Close loading

        if (recognizedIngredients.isNotEmpty) {
          _showRecognitionResults(context, recognizedIngredients);
        } else {
          _showNoIngredientsPopup(context);
        }
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showRecognitionResults(BuildContext context, List<dynamic> ingredients) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final fridgeId = authViewModel.fridgeId;

    if (fridgeId == null || fridgeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fridge ID is missing. Please log in again.')),
      );
      return;
    }

    final Map<String, Map<String, dynamic>> groupedIngredients = {};
    for (var ingredient in ingredients) {
      final name = ingredient['name'];
      if (groupedIngredients.containsKey(name)) {
        groupedIngredients[name]!['quantity'] += 1;
      } else {
        groupedIngredients[name] = {
          'name': name,
          'category': ingredient['category'],
          'id': ingredient['id'],
          'quantity': 1,
        };
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => RecognitionResultsWidget(
        groupedIngredients: groupedIngredients,
        fridgeId: fridgeId,
      ),
    );
  }

  void _showNoIngredientsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('No Ingredients Recognized'),
        content: const Text('No ingredients were recognized in the uploaded image.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      spacing: 10,
      spaceBetweenChildren: 8,
      childPadding: const EdgeInsets.all(4),
      animatedIconTheme: const IconThemeData(size: 22.0),
      children: [
        SpeedDialChild(
          child: const Icon(Icons.restaurant_menu, color: Colors.white),
          backgroundColor: primarySwatch[300],
          label: 'Generate Recipe',
          labelStyle: const TextStyle(fontSize: 12),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => GenerateRecipeScreen()));
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          backgroundColor: primarySwatch[300],
          label: 'Scan Barcode',
          labelStyle: const TextStyle(fontSize: 12),
          onTap: () => _pickImage(context, 'barcode'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.receipt_long, color: Colors.white),
          backgroundColor: primarySwatch[300],
          label: 'Scan Receipt',
          labelStyle: const TextStyle(fontSize: 12),
          onTap: () => _pickImage(context, 'receipt'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.photo_camera, color: Colors.white),
          backgroundColor: primarySwatch[300],
          label: 'Capture Photo',
          labelStyle: const TextStyle(fontSize: 12),
          onTap: () => _pickImage(context, 'photo'),
        ),
      ],
    );
  }
}