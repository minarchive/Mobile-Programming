//simulation.dart

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'smalltalk.dart';
import 'tutorial.dart';
import 'setting.dart';
import 'main.dart';
import 'Simulation_chat.dart'; // 추가
import 'add_chat.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  List<Room> presetRooms = [];
  String searchQuery = ""; // 검색어 상태 변수 추가

  @override
  void initState() {
    super.initState();
    _loadPresetRooms();
  }

  Future<void> _loadPresetRooms() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final presetFile = File('${directory.path}/preset_rooms.json');
      if (await presetFile.exists()) {
        final presetContents = await presetFile.readAsString();
        final List<dynamic> presetJsonData = json.decode(presetContents);
        final loadedRooms =
            presetJsonData.map((data) => Room.fromJson(data)).toList();

        if (mounted) {
          // mounted 체크
          setState(() {
            presetRooms = loadedRooms;
          });
        }
      } else {
        if (mounted) {
          // mounted 체크
          setState(() {
            presetRooms = [
              Room(
                name: 'Alice',
                relationship: 'Friend',
                attitude: 'Friendly',
                imagePath: null,
                summary: 'Loves hiking and outdoor activities.',
                id: 'preset-1',
              ),
              Room(
                name: 'Bob',
                relationship: 'Coworker',
                attitude: 'Professional',
                imagePath: null,
                summary: 'Works in the same team.',
                id: 'preset-2',
              ),
              Room(
                name: 'Charlie',
                relationship: 'Family',
                attitude: 'Caring',
                imagePath: null,
                summary: 'Sibling with a great sense of humor.',
                id: 'preset-3',
              ),
            ];
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // mounted 체크
        setState(() {
          // 오류 처리 (예: 스낵바 표시)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading rooms: $e')),
          );
        });
      }
    }
  }

  Future<void> _savePresetRooms() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final presetFile = File('${directory.path}/preset_rooms.json');
      final presetJsonData = presetRooms.map((room) => room.toJson()).toList();
      await presetFile.writeAsString(json.encode(presetJsonData));
    } catch (e) {
      if (mounted) {
        // mounted 체크
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving rooms: $e')),
        );
      }
    }
  }

  void addPresetRoom(String name, String relationship, String attitude,
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
      presetRooms.add(newRoom);
    });
    _savePresetRooms();
  }

  void presetRoomDialog() async {
    var result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyInterface(requireTxt: false), // 여기서 TXT 비활성화
      ),
    );

    if (result != null) {
      String name = result['name'];
      String relationship = result['relationship'];
      String attitude = result['attitude'];
      String? imagePath = result['imagePath'];
      String summary = result['summary'];

      // 이미지 파일 검증 추가
      if (imagePath != null && !_isValidImageFile(imagePath)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid image file.')),
        );
        return;
      }

      addPresetRoom(name, relationship, attitude, imagePath, summary);
    } else {
      if (kDebugMode) {
        print('No data received');
      }
    }
  }

// 이미지 파일 유효성 검사 함수 추가
  bool _isValidImageFile(String filePath) {
    final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp'];
    final fileExtension = filePath.split('.').last.toLowerCase();
    return validExtensions.contains(fileExtension);
  }



  void deletePresetRoom(Set<Room> roomsToDelete) {
    setState(() {
      presetRooms.removeWhere((room) => roomsToDelete.contains(room));
    });
    _savePresetRooms();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted successfully')),
    );
  }

  void selectDeletePresetRoomDialog() {
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
                  children: presetRooms.map(buildRoomCheckbox).toList(),
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
                      deletePresetRoom(selectedRooms);
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
      presetRoomDialog();
    } else if (option == 'Delete') {
      if (presetRooms.isNotEmpty) {
        selectDeletePresetRoomDialog();
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
    // searchQuery로 필터링된 목록 생성
    List<Room> filteredRooms = presetRooms.where((room) {
      return room.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100], // 전체 화면 배경색
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
            'Simulation Screen',
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
            // 검색창 추가 (MainScreen과 동일한 UI)
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
            // 채팅방 목록
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
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
                                builder: (context) => SimulationChattingScreen(
                                  room: room,
                                  isPreset: true,
                                ),
                              ),
                            );
                            _savePresetRooms();
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
              icon: Icon(Icons.home),
              label: 'Main',
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
                      const MainScreen(),
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
