import 'package:flutter/material.dart';

// 메인화면 임포트 필요
import 'main.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int currentIndex = 0;
  final List<String> tutorialImages = [
    'assets/tutorial1.png',
    'assets/tutorial2.png',
    'assets/tutorial3.png',
    'assets/tutorial4.png',
    'assets/tutorial5.png',
    'assets/tutorial6.png',
    'assets/tutorial7.png',
    'assets/tutorial8.png'
  ];

  void _goPrevious() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
    // 첫 번째 이미지에서 왼쪽 버튼을 눌러도 아무 변화 없음
  }

  void _goNext() {
    if (currentIndex < tutorialImages.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
    // 마지막 이미지에서 오른쪽 버튼을 눌러도 아무 변화 없음
  }

  void _goMain() {
    // 메인 화면으로 돌아가기
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  void _handleTap(TapDownDetails details) {
    final width = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (dx < width / 2) {
      _goPrevious();
    } else {
      _goNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 반투명 배경
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTap,
        child: Stack(
          children: [
            Container(color: Colors.black54),
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // 상단 Exit 버튼
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: _goMain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Image.asset(
                            tutorialImages[currentIndex],
                            width: MediaQuery.of(context).size.width * 0.7,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${currentIndex + 1} / ${tutorialImages.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 40), // 버튼 대신 여백을 추가
                    ],
                  ),
                ),
              ),
            ),
            // 왼쪽 화살표 버튼
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  iconSize: 50,
                  icon: const Icon(Icons.arrow_left, color: Colors.white),
                  onPressed: _goPrevious,
                ),
              ),
            ),
            // 오른쪽 화살표 버튼
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  iconSize: 50,
                  icon: const Icon(Icons.arrow_right, color: Colors.white),
                  onPressed: _goNext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
