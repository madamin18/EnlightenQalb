import 'dart:convert';
// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testapp/pages/login_response.dart'; // Ensure correct path

class ApiService {
  static const String baseUrl =
      "https://humblebeeai-al-ghazali-rag-retrieval-api.hf.space";

  // ✅ Function to perform a search query
  static Future<List<dynamic>> search(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access_token");

    if (token == null) {
      throw Exception("Access token not found. Please log in.");
    }

    final url = Uri.parse("$baseUrl/search");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "query": query,
      }),
    );

    // ✅ Handling response and errors
    if (response.statusCode == 200) {
      // Return the list of search results
      print("Search results: ${response.body}");
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception(
          "Unauthorized. Please refresh the token or log in again.");
    } else {
      throw Exception(
          "Failed to fetch search results. Status: ${response.statusCode}");
    }
  }

  // ✅ Optional: Function to refresh the access token (reused from earlier implementation)
  static Future<LoginResponse> refreshToken(String refreshToken) async {
    final url = Uri.parse('$baseUrl/refresh');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh_token": refreshToken}),
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to refresh token: ${response.body}');
    }
  }
}
