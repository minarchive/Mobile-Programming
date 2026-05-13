import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'main.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChattingScreen extends StatefulWidget {
  final Room room;

  const ChattingScreen({Key? key, required this.room}) : super(key: key);

  @override
  State<ChattingScreen> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
  final TextEditingController controller = TextEditingController();
  String currentSender = 'Assistant';
  final ScrollController _scrollController = ScrollController();

  final Map<int, bool> _collapsedStates = {};
  String? _lastUserMessageTriggeredLlama;

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
        widget.room.messages.add(
          Message(
              sender: currentSender,
              text: messageText,
              isLlamaRecommendation: false),
        );
        widget.room.lastMessage = messageText;
        widget.room.lastMessageTime = DateTime.now();
        controller.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      if (currentSender == 'User') {
        final lastIndex = widget.room.messages.length - 1;
        if (lastIndex > 0 && widget.room.messages[lastIndex - 1].sender == 'Llama') {
          final llamaIndex = lastIndex - 1;
          if (_collapsedStates[llamaIndex] == false) {
            _collapsedStates[llamaIndex] = true;
          }
        }

        _sendMessageToLlama(messageText);
      }
    }
  }

  Future<void> _sendMessageToLlama(String message) async {
    if (!await _checkInternetConnection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your Wi-Fi.'),
        ),
      );
      return;
    }

    final contextMessages = widget.room.messages
        .where((msg) =>
    (msg.sender == 'Assistant' && !msg.isLlamaRecommendation) ||
        (msg.sender == 'User' && !msg.isLlamaRecommendation))
        .toList();

    final contextText =
    contextMessages.map((msg) => '${msg.sender}: ${msg.text}').join("\n");

    final prompt = '''
YOU SHOULD FOLLOW THE INSTRUCTIONS BELOW CAREFULLY.

You are an assistant with a ${widget.room.attitude} attitude, highly knowledgeable, and empathetic. Your goal is to answer in a way that feels natural, engaging, and perfectly suited to casual conversations.

The user is your ${widget.room.relationship}, and you should treat them with warmth, humor, and respect.

When the user asks a question or shares something, you must provide three engaging and friendly responses in the tone of a good friend.

- Response 1 (Very Short): A snappy and witty reply, no more than 5-8 words.
- Response 2 (Short): A friendly and slightly humorous response, up to 20 words.
- Response 3 (Medium): A conversational reply with personality, weaving in warmth, humor, or curiosity, up to 50 words.

Your responses should balance humor and relevance, while remaining light-hearted and relatable.

Here’s some context to guide your responses:
- Summary of the previous chat: "${widget.room.summary}"
- Current message: "$message"

Make sure all responses feel conversational and natural. Inject a bit of personality, wit, or playfulness to make the user feel connected and valued.

Context of the conversation: $contextText

Your task is to generate the best three responses below:

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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final apiResponse = data['choices'][0]['message']['content'];

        setState(() {
          widget.room.messages.add(
            Message(
                sender: 'Llama', text: apiResponse, isLlamaRecommendation: true),
          );
          widget.room.lastMessage = apiResponse;
          widget.room.lastMessageTime = DateTime.now();
          _lastUserMessageTriggeredLlama = message;
        });
      } else {
        setState(() {
          final errorMessage =
              'Llama: Failed to get response. Status: ${response.statusCode}';
          widget.room.messages.add(
            Message(
                sender: 'Llama',
                text: errorMessage,
                isLlamaRecommendation: true),
          );
          widget.room.lastMessage = errorMessage;
          widget.room.lastMessageTime = DateTime.now();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please check your Wi-Fi.')),
      );
      // Show a message if no connection or API fail

    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _saveChatRoom();
  }

  Future<void> _saveChatRoom() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/chat_rooms.json');

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

  Widget _buildLlamaMessage(
      Message message, int index, bool isSameSenderAsPrevious) {
    if (!_collapsedStates.containsKey(index)) {
      bool isLastMessage = index == widget.room.messages.length - 1;
      _collapsedStates[index] = isLastMessage ? false : true;
    }

    final isCollapsed = _collapsedStates[index]!;

    return Padding(
      padding:
      EdgeInsets.only(top: isSameSenderAsPrevious ? 2.0 : 8.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!isSameSenderAsPrevious) const SizedBox(height: 4.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.orange[200],
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Recommendation",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8.0),
                        if (!isCollapsed)
                          Text(
                            message.text,
                            style: const TextStyle(
                                color: Colors.black,
                                fontFamilyFallback: ['Noto Sans', 'Noto Color Emoji']),
                            textAlign: TextAlign.center,
                          ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _collapsedStates[index] = !isCollapsed;
                              });
                            },
                            child: Icon(
                              isCollapsed ? Icons.expand_more : Icons.expand_less,
                              color: Colors.black45,
                              size: 24.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, int index) {
    final message = widget.room.messages[index];
    final isUserMessage = message.sender == 'User';
    final isAssistantMessage = message.sender == 'Assistant';
    final isLlamaMessage = message.sender == 'Llama';

    final bool isSameSenderAsPrevious = index > 0 &&
        widget.room.messages[index - 1].sender == message.sender &&
        widget.room.messages[index - 1].isLlamaRecommendation ==
            message.isLlamaRecommendation;

    if (isLlamaMessage) {
      return Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          setState(() {
            widget.room.messages.removeAt(index);
          });
        },
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20.0),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: _buildLlamaMessage(message, index, isSameSenderAsPrevious),
      );
    } else if (isUserMessage) {
      return Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          setState(() {
            widget.room.messages.removeAt(index);
          });
        },
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20.0),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: isSameSenderAsPrevious ? 2.0 : 8.0, bottom: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSameSenderAsPrevious) ...[
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4.0),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 56.0),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(right: 16.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(
                              color: Colors.black,
                              fontFamilyFallback: ['Noto Sans', 'Noto Color Emoji']),
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
    } else if (isAssistantMessage) {
      return Dismissible(
        key: UniqueKey(),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          setState(() {
            widget.room.messages.removeAt(index);
          });
        },
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20.0),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: isSameSenderAsPrevious ? 2.0 : 8.0, bottom: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isSameSenderAsPrevious) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      message.sender == 'Assistant' ? 'User' : message.sender,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
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
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.6,
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(left: 16.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamilyFallback: ['Noto Sans', 'Noto Color Emoji']),
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
    } else {
      return const SizedBox.shrink();
    }
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
                return _buildMessageItem(context, index);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: currentSender == 'Assistant'
                        ? Colors.blue
                        : Colors.grey,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        currentSender =
                        currentSender == 'Assistant' ? 'User' : 'Assistant';
                      });
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            currentSender == 'Assistant'
                                ? Icons.person
                                : Icons.people,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentSender == 'Assistant'
                                ? 'User'
                                : 'Agent',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                        fontFamilyFallback: ['Noto Sans', 'Noto Color Emoji']),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
