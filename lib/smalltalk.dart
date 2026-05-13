//smalltalk.dart

import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // llama3 API 호출을 위해 추가
import 'main.dart';
import 'setting.dart';
import 'simulation.dart';
import 'tutorial.dart';

class SmalltalkScreen extends StatefulWidget {
  const SmalltalkScreen({super.key});

  @override
  State<SmalltalkScreen> createState() => _SmalltalkScreenState();
}

class _SmalltalkScreenState extends State<SmalltalkScreen> {
  final List<Map<String, dynamic>> topics = [
    {
      'title': 'Conversation at the First Meeting',
      'icon': Icons.person,
      'items': [
        'Brief introduction',
        'MBTI',
        'Birthday',
        'Alcohol/Cigarette status',
        'Major and current job',
      ],
    },
    {
      'title': 'Travel-related Smalltalk',
      'icon': Icons.airplane_ticket,
      'items': [
        'Preferred travel style (recreational vs active)',
        'Domestic travel vs. overseas travel',
        'A travel destination I want to go to',
        'A travel destination I have been to before',
        'What was the most memorable thing during the trip',
      ],
    },
    {
      'title': 'A Conversation about Food',
      'icon': Icons.restaurant,
      'items': [
        'My favorite food',
        'Food you cannot eat',
        'A good cook',
        'Preference for spicy food',
        'My favorite cafe',
      ],
    },
    {
      'title': 'Movies and Dramas',
      'icon': Icons.movie,
      'items': [
        'Favorite movie/drama',
        'Life movie/drama',
        'A memorable scene',
        'Your favorite genre',
        'The most recent work you\'ve seen',
      ],
    },
    {
      'title': 'Conversations about Music',
      'icon': Icons.music_note,
      'items': [
        'Favorite song',
        'Your favorite music genre',
        'Favorite singer',
        'Karaoke No. 18',
        'Recent music you enjoy listening to',
      ],
    },
    {
      'title': 'Interests and Hobbies',
      'icon': Icons.sports,
      'items': [
        'Exercise preference',
        'Recent hobby',
        'Favorite season',
        'With or without pets',
        'What do you want to learn?',
      ],
    },
  ];

  // 화면 전환 후에도 데이터를 유지하기 위한 정적 변수
  static List<String> savedRecommendedTopics = [];

  List<String> recommendedTopics = [];

  @override
  void initState() {
    super.initState();
    // 이미 저장된 추천 토픽이 있다면 복원
    if (savedRecommendedTopics.isNotEmpty) {
      recommendedTopics = List.from(savedRecommendedTopics);
    }
  }

  Future<bool> _checkInternetConnection(BuildContext context) async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      // 네트워크 연결 안 됨
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Please check your network settings.'),
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }

    return true; // 연결됨
  }


  Future<void> _getRecommendedTopics() async {



    const prompt = '''
please recommend smalltalking conversation contents about various things.
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
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apiResponseDynamic = data['choices'][0]['message']['content'];
        final apiResponse = apiResponseDynamic is String
            ? apiResponseDynamic
            : (apiResponseDynamic?.toString() ?? '');

        final lines = apiResponse
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .take(5)
            .toList();

        if (!mounted) return; // mount 체크
        setState(() {
          recommendedTopics = lines;
          savedRecommendedTopics = List.from(lines); // 정적 변수에 저장
        });
      } else {
        if (!mounted) return; // mount 체크
        setState(() {
          recommendedTopics = [
            'Failed to get recommended topics. Status: ${response.statusCode}'
          ];
          savedRecommendedTopics = List.from(recommendedTopics); // 저장
        });
      }
    } catch (e) {
      if (!mounted) return; // 화면이 언마운트된 경우 중단
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please check your Wi-Fi.')),

      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allTopics = List.from(topics);

    if (recommendedTopics.isNotEmpty) {
      allTopics.add({
        'title': 'Recommended Topics from Llama',
        'icon': Icons.auto_awesome,
        'items': recommendedTopics,
      });
    }

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
            'Smalltalk Recommendation',
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
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        itemCount: allTopics.length,
        itemBuilder: (context, index) {
          final topic = allTopics[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            elevation: 3,
            color: Colors.white.withOpacity(0.95), // 카드 배경색
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(topic['icon'], size: 28, color: Colors.grey[700]),
                      const SizedBox(width: 10),
                      Text(
                        topic['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...topic['items'].asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;

                    if (topic['title'] == 'Recommended Topics from Llama') {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else if (i == 1) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            '[ $item ]',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }
                    } else {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '• $item',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }
                  }).toList(),
                ],
              ),
            ),
          );
        },
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
              icon: Icon(Icons.search),
              label: 'Simulation',
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
                      const SimulationScreen(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _getRecommendedTopics,
        child: const Icon(Icons.auto_awesome),
      ),
    );
  }
}
