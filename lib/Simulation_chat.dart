import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'main.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SimulationChattingScreen extends StatefulWidget {
  final Room room;
  final bool isPreset;

  const SimulationChattingScreen({
    Key? key,
    required this.room,
    required this.isPreset,
  }) : super(key: key);

  @override
  State<SimulationChattingScreen> createState() =>
      _SimulationChattingScreenState();
}

class _SimulationChattingScreenState extends State<SimulationChattingScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String currentSender = 'User';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<bool> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void sendMessage() async {



    if (controller.text.isNotEmpty) {
      final messageText = controller.text;
      setState(() {
        widget.room.messages.add(Message(sender: currentSender, text: messageText));
        widget.room.lastMessage = messageText;
        widget.room.lastMessageTime = DateTime.now();
        controller.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      await _sendMessage(messageText);
    }
  }

  Future<void> _sendMessage(String message) async {
    final contextMessages =
    widget.room.messages.map((msg) => '${msg.sender}: ${msg.text}').join("\n");

    final prompt = '''
YOU ARE A CONVERSATIONAL ASSISTANT.

Your personality is defined as ${widget.room.attitude}, and you behave like a close friend to the user. Your tone is friendly, casual, and witty, while still ensuring your responses are thoughtful and helpful.

The user is your ${widget.room.relationship}. This means:
- Respond naturally, as if you're talking to a good friend.
- Use humor, playful banter, or relatable language where appropriate.
- Keep it **short and casual**—no long paragraphs unless the user asks for detailed information.

**Context of the Conversation**:
${widget.room.summary}

**Important Guidelines**:
1. Keep your responses **concise and to the point**, while staying engaging and fun.
2. Balance wit and clarity. Be playful, but don’t sacrifice helpfulness.
3. Always refer back to the summary or recent context if it enhances the flow, but **avoid over-explaining**.
4. Aim for sentences or replies that could fit into a friendly text message.

$contextMessages
User: $message
Assistant:
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
          'Bearer your own API key',
        },
        body: json.encode({
          'model': 'llama-3.3-70b-specdec',
          'messages': [
            {'role': 'user', 'content': prompt}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));;
        final apiResponse = data['choices'][0]['message']['content'];
        setState(() {
          widget.room.messages.add(Message(sender: 'Assistant', text: apiResponse));
          widget.room.lastMessage = apiResponse;
          widget.room.lastMessageTime = DateTime.now();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        setState(() {
          final errorMessage =
              'Assistant: Failed to get response. Status: ${response.statusCode}';
          widget.room.messages.add(Message(sender: 'Assistant', text: errorMessage));
          widget.room.lastMessage = errorMessage;
          widget.room.lastMessageTime = DateTime.now();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      // Show message if connection fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please check your Wi-Fi.')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _saveChatRoom();
  }

  Future<void> _saveChatRoom() async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = widget.isPreset ? 'preset_rooms.json' : 'your_rooms.json';
    final file = File('${directory.path}/$fileName');

    List<Room> allRooms = [];
    if (await file.exists()) {
      final contents = await file.readAsString();
      final List<dynamic> jsonData = json.decode(contents);
      allRooms = jsonData.map((data) => Room.fromJson(data)).toList();
    }

    int index = allRooms.indexWhere((room) => room.id == widget.room.id);
    if (index != -1) {
      allRooms[index] = widget.room;
    } else {
      allRooms.add(widget.room);
    }

    final jsonData = allRooms.map((room) => room.toJson()).toList();
    await file.writeAsString(json.encode(jsonData));
  }

  void _showEmojiPicker() {
    final emojis = ['😀', '😂', '😍', '🤔', '👍', '🙏', '🔥', '✨'];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: emojis.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                setState(() {
                  controller.text += emojis[index];
                });
                Navigator.pop(context);
              },
              child: Center(
                child: Text(
                  emojis[index],
                  style: const TextStyle(fontSize: 24.0),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leadingWidth: 60,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.arrow_back, color: Colors.black, size: 20),
            ),
          ),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18.0,
              backgroundImage: widget.room.imagePath != null
                  ? FileImage(File(widget.room.imagePath!))
                  : null,
              child: widget.room.imagePath == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              widget.room.name,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: widget.room.messages.length,
              itemBuilder: (context, index) {
                final message = widget.room.messages[index];
                final isUserMessage = message.sender == 'User';

                if (!isUserMessage) {
                  // 기존 상대방 메시지 삭제 처리 로직 유지
                  return Dismissible(
                    key: Key(message.text + index.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      setState(() {
                        widget.room.messages.removeAt(index);
                      });
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 8.0),
                              CircleAvatar(
                                radius: 16.0,
                                backgroundImage: widget.room.imagePath != null
                                    ? FileImage(File(widget.room.imagePath!))
                                    : null,
                                child: widget.room.imagePath == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                widget.room.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: 56.0),
                              Flexible(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                    MediaQuery.of(context).size.width * 0.6,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        right: 16.0, bottom: 4.0),
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      message.text,
                                      style: const TextStyle(color: Colors.black),
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
                } else {
                  // 사용자 메시지에도 Dismissible 추가
                  return Dismissible(
                    key: Key(message.text + index.toString()),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      setState(() {
                        widget.room.messages.removeAt(index);
                      });
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                message.sender,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              const SizedBox(width: 8.0),
                              const CircleAvatar(
                                radius: 16.0,
                                child: Icon(Icons.person),
                              ),
                              const SizedBox(width: 8.0),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                    MediaQuery.of(context).size.width * 0.6,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        left: 16.0, bottom: 4.0),
                                    padding: const EdgeInsets.all(8.0),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      message.text,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 56.0),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions, color: Colors.grey),
                  onPressed: _showEmojiPicker, // 이모지 선택 기능
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Input Message.',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
