//setting.dart

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'simulation.dart';
import 'smalltalk.dart';
import 'tutorial.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';
import 'theme_provider.dart';
import 'character_provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final String privacyPolicyUrl =
      'https://www.notion.so/Privacy-Policy-141faed6a78c808d854de6963e408b63?pvs=4';
  final String contactUsUrl =
      'https://www.notion.so/Contract-Page-141faed6a78c80ee9c7ec3581e57978b?pvs=4';
  final String appVersion = '0.1.0';

  void _showThemeDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Select a Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('General Mode'),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Mode'),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCharacterDialog(BuildContext context) {
    final characterProvider =
        Provider.of<CharacterProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Select a Character'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  characterProvider.setCharacter('assets/char1.png');
                  Navigator.of(context).pop();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      Image.asset('assets/char1.png', width: 100, height: 100),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  characterProvider.setCharacter('assets/char2.png');
                  Navigator.of(context).pop();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      Image.asset('assets/char2.png', width: 100, height: 100),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  characterProvider.setCharacter('assets/char3.png');
                  Navigator.of(context).pop();
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      Image.asset('assets/char3.png', width: 100, height: 100),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Future<bool> _checkInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void _launchURL(String url) async {
    if (!await _checkInternetConnection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please check your Wi-Fi.')),
      );
      return;
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open URL.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'Settings',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // _buildSettingCard(
            //   title: 'Theme',
            //   icon: Icons.color_lens,
            //   onTap: () => _showThemeDialog(context),
            // ), 다크모드 기능 삭제
            _buildDivider(),
            _buildSettingCard(
              title: 'Character',
              icon: Icons.face,
              onTap: () => _showCharacterDialog(context),
            ),
            _buildDivider(),
            _buildSettingCard(
              title: 'Personal Information Policy',
              icon: Icons.privacy_tip,
              onTap: () => _launchURL(privacyPolicyUrl),
            ),
            _buildDivider(),
            _buildSettingCard(
              title: 'Contact Us',
              icon: Icons.contact_mail,
              onTap: () => _launchURL(contactUsUrl),
            ),
            _buildDivider(),
            _buildSettingCard(
              title: 'Version',
              icon: Icons.info,
              trailing: const Text(
                '1.0.0',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              onTap: () {}, // Version 항목은 클릭하지 않아도 되므로 빈 콜백 처리
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
              icon: Icon(Icons.search),
              label: 'Simulation',
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
                      const SimulationScreen(),
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

  Widget _buildSettingCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 0),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 10);
  }
}
