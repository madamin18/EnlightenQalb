import 'package:flutter/material.dart';
import 'package:testapp/pages/api_service.dart';
import 'package:testapp/pages/home_page2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:testapp/pages/login_page.dart';

class HomePage extends StatefulWidget {
  final String role;
  final String username;

  const HomePage({super.key, required this.role, required this.username});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  final List<List<dynamic>> _searchResults = [];
  final ScrollController _scrollController = ScrollController();
  final Map<int, int> _reactionData = {};
  bool _canSave = false;
  bool _isSaving = false;

  String username = "";
  String userType = "";

  @override
  void initState() {
    super.initState();
    userType = widget.role;
    username = widget.username;
  }

  Future<void> _saveData() async {
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please type a message before saving."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    List<Map<String, dynamic>> items = [];

    for (int i = 0; i < _messages.length; i++) {
      String userMessage = _messages[i];
      List<dynamic> responses =
          _searchResults.length > i ? _searchResults[i] : [];

      for (int j = 0; j < responses.length; j++) {
        int reactionIndex = i * 2 + j;
        if (!_reactionData.containsKey(reactionIndex)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Please select reactions for all responses before saving."),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      for (int j = 0; j < responses.length; j++) {
        Map<String, dynamic> response = responses[j];
        int reactionIndex = i * 2 + j;
        String reaction = _mapReactionToString(_reactionData[reactionIndex]);

        items.add({
          "user_type": userType,
          "username": username,
          "query": userMessage,
          "retrieved_text": response["text"] ?? "No response",
          "model_type": response["model_type"] ?? "N/A",
          "reaction": reaction,
        });
      }
    }

    final body = {"items": items};

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("access_token");

      if (token == null) {
        throw Exception("Access token not found. Please log in.");
      }

      final url = Uri.parse(
          "https://humblebeeai-al-ghazali-rag-retrieval-api.hf.space/save");
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Data saved successfully"),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _messages.clear();
          _searchResults.clear();
          _reactionData.clear();
          _canSave = false;
        });
      } else {
        throw Exception("Failed to save data: ${response.body}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String _mapReactionToString(int? reaction) {
    switch (reaction) {
      case -1:
        return "👎";
      case 0:
        return "🤷";
      case 1:
        return "👍";
      default:
        return "🤷";
    }
  }

  Future<void> _sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isNotEmpty) {
      setState(() {
        _messages.add(userMessage);
        _searchResults.add([]);
        _canSave = true;
      });
      _controller.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      try {
        final results = await ApiService.search(userMessage);
        setState(() {
          _searchResults[_messages.length - 1] = results;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setReaction(int index, int reaction) {
    setState(() {
      _reactionData[index] = reaction;
    });
  }

  Future<void> _logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.role,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : GestureDetector(
                    onTap: _canSave ? _saveData : null,
                    child: Text(
                      "Save",
                      style: TextStyle(
                        color: _canSave ? Colors.white : Colors.white,
                        fontSize: 19,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'User: $username',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Role: ${widget.role}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: _logoutUser,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final responses = _searchResults[index];
                final firstResponse = responses.isNotEmpty
                    ? responses[0]
                    : {
                        "text": "Waiting for response...",
                        "similarity": "N/A",
                        "model_type": "N/A"
                      };
                final secondResponse = responses.length > 1
                    ? responses[1]
                    : {
                        "text": "Waiting for response...",
                        "similarity": "N/A",
                        "model_type": "N/A"
                      };

                return Column(
                  children: [
                    _buildUserMessage(_messages[index]),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildResponseCard(firstResponse, index * 2),
                            const SizedBox(width: 10),
                            _buildResponseCard(secondResponse, index * 2 + 1),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(String message) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildResponseCard(Map<String, dynamic> response, int responseIndex) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            response['text'] ?? "No response available.",
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.thumb_down,
                  color: _reactionData[responseIndex] == -1
                      ? Colors.red
                      : Colors.grey),
              onPressed: () => _setReaction(responseIndex, -1),
            ),
            IconButton(
              icon: Icon(Icons.thumbs_up_down,
                  color: _reactionData[responseIndex] == 0
                      ? Colors.yellow
                      : Colors.grey),
              onPressed: () => _setReaction(responseIndex, 0),
            ),
            IconButton(
              icon: Icon(Icons.thumb_up,
                  color: _reactionData[responseIndex] == 1
                      ? Colors.green
                      : Colors.grey),
              onPressed: () => _setReaction(responseIndex, 1),
            ),
          ],
        ),
      ],
    );
  }
}
