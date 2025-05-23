import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/token_util.dart';

class CookbookService {
  final String baseUrl = dotenv.env['SERVER_IP'] ?? '';  

  // Fetch all recipes in the cookbook
  Future<List<dynamic>> fetchCookbookRecipes(String cookbookId) async {
    final token = await TokenUtil.getAccessToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/cookbook/$cookbookId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );    

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('cookbook')) {
        final cookbook = data['cookbook'];
        if (cookbook is Map<String, dynamic> &&
            cookbook.containsKey('recipes')) {
          return cookbook['recipes'] as List<dynamic>;
        } else {
          throw Exception('Unexpected cookbook format: ${response.body}');
        }
      } else {
        throw Exception('Unexpected response format: ${response.body}');
      }
    } else {
      throw Exception(
          'Failed to fetch cookbook recipes: ${response.statusCode}');
    }
  }

  // Add a new recipe to the cookbook
  Future<bool> addRecipeToCookbook(
      Map<String, dynamic> recipeData, String cookbookId) async {
    final token = await TokenUtil.getAccessToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/cookbook/$cookbookId/recipes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(recipeData),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      throw Exception(
          'Failed to add recipe to cookbook: ${response.statusCode}');
    }
  }

  // Update a recipe in the cookbook
  Future<bool> updateCookbookRecipe(String cookbookId, String recipeId,
      Map<String, dynamic> updatedData) async {
    final token = await TokenUtil.getAccessToken();
    final response = await http.put(
      Uri.parse('$baseUrl/api/cookbook/$cookbookId/recipes/$recipeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updatedData),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
          'Failed to update cookbook recipe: ${response.statusCode}');
    }
  }

  // Delete a recipe from the cookbook
  Future<bool> deleteCookbookRecipe(String cookbookId, String recipeId) async {
    final token = await TokenUtil.getAccessToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/cookbook/$cookbookId/recipes/$recipeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception(
          'Failed to delete cookbook recipe: ${response.statusCode}');
    }
  }
}
