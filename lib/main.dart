import 'dart:io';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'chatting.dart';
import 'package:intl/intl.dart';
import 'add_chat.dart';
import 'simulation.dart';
import 'smalltalk.dart';
import 'tutorial.dart';
import 'setting.dart';
import 'dart:async';
import 'character_provider.dart';
import 'theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CharacterProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class Message {
  final String sender;
  final String text;
  final bool isLlamaRecommendation;

  Message({
    required this.sender,
    required this.text,
    this.isLlamaRecommendation = false,
  });

  Map<String, dynamic> toJson() => {
    'sender': sender,
    'text': text,
    'isLlamaRecommendation': isLlamaRecommendation,
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      text: json['text'],
      isLlamaRecommendation: json['isLlamaRecommendation'] ?? false,
    );
  }
}

class Room {
  final String id;
  final String name;
  final String relationship;
  final String attitude;
  final String? imagePath;
  final String summary;
  String lastMessage;
  DateTime? lastMessageTime;
  List<Message> messages;

  Room({
    required this.id,
    required this.name,
    required this.relationship,
    required this.attitude,
    required this.imagePath,
    required this.summary,
    this.lastMessage = '',
    DateTime? lastMessageTime,
    List<Message>? messages,
  })  : lastMessageTime = lastMessageTime ?? DateTime.now(),
        messages = messages ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'attitude': attitude,
    'imagePath': imagePath,
    'summary': summary,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime?.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      name: json['name'],
      relationship: json['relationship'],
      attitude: json['attitude'],
      imagePath: json['imagePath'],
      summary: json['summary'],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      messages:
      (json['messages'] as List).map((m) => Message.fromJson(m)).toList(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Chat Application',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      // Ensure fonts support multiple languages and emojis
      builder: (context, child) {
        return DefaultTextStyle(
          style: const TextStyle(fontFamilyFallback: ['Noto Sans', 'Noto Color Emoji']),
          child: child!,
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCharacter =
        Provider.of<CharacterProvider>(context).selectedCharacter;

    return Scaffold(
      backgroundColor: const Color(0xFF42A5F5),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              selectedCharacter,
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "Loading...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Room> chattingRooms = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
 //   initConnectivity();
    _checkWifiConnection();
  }
  Future<void> _checkWifiConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    // Wi-Fi가 연결되지 않은 경우에만 Snackbar를 표시
    if (connectivityResult.contains(ConnectivityResult.none)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No internet connection. Please check your Wi-Fi.'),
          duration: Duration(seconds: 3),
        ),
      );

    }
  }
  Future<void> initConnectivity() async {
    ConnectivityResult result;
    try {
      result = (await Connectivity().checkConnectivity()) as ConnectivityResult;
    } catch (e) {
      print('Error checking connectivity: $e');
      return;
    }

    if (result == ConnectivityResult.none) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Network Connection'),
          content: const Text('Please connect to the internet and try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadChatRooms() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/chat_rooms.json');

    if (await file.exists()) {
      final contents = await file.readAsString();
      final List<dynamic> jsonData = json.decode(contents);

      if (!mounted) return;

      setState(() {
        chattingRooms = jsonData.map((data) => Room.fromJson(data)).toList();
      });
    }
  }

  Future<void> _saveChatRooms() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/chat_rooms.json');
    final jsonData = chattingRooms.map((room) => room.toJson()).toList();
    await file.writeAsString(json.encode(jsonData));
  }

  void addChattingRoom(String name, String relationship, String attitude,
      String? imagePath, String summary) {
    setState(() {
      final newRoom = Room(
        name: name,
        relationship: relationship,
        attitude: attitude,
        imagePath: imagePath,
        summary: summary,
        id: DateTime.now().toString(),
      );
      chattingRooms.add(newRoom);
    });
    _saveChatRooms();
  }

  void chattingRoomDialog() async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyInterface(),
      ),
    );

    if (result != null) {
      String name = result['name'];
      String relationship = result['relationship'];
      String attitude = result['attitude'];
      String? imagePath = result['imagePath'];
      String summary = result['summary'];

      addChattingRoom(name, relationship, attitude, imagePath, summary);
    }
  }

  void deleteChattingRoom(Set<Room> roomsToDelete) {
    setState(() {
      chattingRooms.removeWhere((room) => roomsToDelete.contains(room));
    });
    _saveChatRooms();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted successfully')),
    );
  }

  void selectDeleteChattingRoomDialog() {
    final Set<Room> selectedRooms = {};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Widget buildRoomCheckbox(Room room) {
              return CheckboxListTile(
                title: Text(room.name),
                value: selectedRooms.contains(room),
                onChanged: (bool? isChecked) {
                  setStateDialog(() {
                    if (isChecked == true) {
                      selectedRooms.add(room);
                    } else {
                      selectedRooms.remove(room);
                    }
                  });
                },
              );
            }

            return AlertDialog(
              title: const Text('Select Rooms to Delete'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: chattingRooms.map(buildRoomCheckbox).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                if (selectedRooms.isNotEmpty)
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () {
                      deleteChattingRoom(selectedRooms);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Delete'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void handleMenuSelection(String option) {
    if (option == 'Add') {
      chattingRoomDialog();
    } else if (option == 'Delete') {
      if (chattingRooms.isNotEmpty) {
        selectDeleteChattingRoomDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No rooms to delete')),
        );
      }
    }
  }

  Widget customIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color iconColor = Colors.black87,
  }) {
    return IconButton(
      icon: Icon(icon, color: iconColor),
      iconSize: 20,
      padding: const EdgeInsets.all(0),
      constraints: const BoxConstraints(),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Room> filteredRooms = chattingRooms.where((room) {
      return room.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text(
            'Main Screen',
            style: TextStyle(
              fontWeight: FontWeight.w200,
              fontSize: 25,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        actions: [
          customIconButton(
            icon: Icons.add,
            onPressed: () => handleMenuSelection('Add'),
            iconColor: Colors.blue,
          ),
          const SizedBox(width: 4),
          customIconButton(
            icon: Icons.remove,
            onPressed: () => handleMenuSelection('Delete'),
            iconColor: Colors.red,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 2,
                  ),
                ],
              ),
              child: SizedBox(
                height: 50,
                child: TextField(
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                    suffixIcon: Icon(Icons.search, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 14.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredRooms.length,
                    itemBuilder: (BuildContext context, int index) {
                      final room = filteredRooms[index];

                      final now = DateTime.now();
                      String timeDisplay;
                      if (room.lastMessageTime != null) {
                        final difference =
                        now.difference(room.lastMessageTime!);
                        if (difference.inDays > 1) {
                          timeDisplay =
                              DateFormat('MM/dd').format(room.lastMessageTime!);
                        } else if (difference.inDays == 1) {
                          timeDisplay = 'Yesterday';
                        } else {
                          timeDisplay =
                              DateFormat('HH:mm').format(room.lastMessageTime!);
                        }
                      } else {
                        timeDisplay = '';
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: room.imagePath != null
                                ? FileImage(File(room.imagePath!))
                                : null,
                            child: room.imagePath == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          title: Text(
                            room.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            'Relationship: ${room.relationship}\nAttitude: ${room.attitude}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          trailing: Text(
                            timeDisplay,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChattingScreen(room: room),
                              ),
                            );
                            _saveChatRooms();
                          },
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return const Divider(color: Colors.grey, thickness: 0.5);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 14,
          unselectedFontSize: 12,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: const Icon(Icons.info, color: Colors.white),
              ),
              label: 'Tutorial',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Simulation',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Smalltalk',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                  const TutorialScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                  const SimulationScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                  const SmalltalkScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            } else if (index == 3) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation1, animation2) =>
                  const SettingScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
