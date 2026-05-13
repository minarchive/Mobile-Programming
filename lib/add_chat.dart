import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class MyInterface extends StatefulWidget {
  final bool requireTxt; // 추가: TXT 파일 요구 여부

  const MyInterface({super.key, this.requireTxt = true});

  @override
  _MyInterfaceState createState() => _MyInterfaceState();
}

class _MyInterfaceState extends State<MyInterface> {
  String dropdownValue = 'neutrality';
  String name = '';
  String relationship = '';
  String attitude = 'neutrality';
  String? _filePath;
  String? _imagePath;
  String summary = '';
  final picker = ImagePicker();
  final TextSummarizer textSummarizer = TextSummarizer();
  bool isLoading = false;
  bool isDropdownOpen = false;

  Future<void> _pickImage() async {
    setState(() {
      isLoading = true;
    });
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {

      // 이미지 파일 확장자 확인
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp'];
      final extension = path.extension(pickedFile.path).toLowerCase();
      if (!validExtensions.contains(extension.replaceFirst('.', ''))) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid image file (JPG, PNG, GIF, BMP).')),
        );
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage =
      await File(pickedFile.path).copy('${appDir.path}/$fileName');

      setState(() {
        _imagePath = savedImage.path;
      });
    } else {
      print('No image selected.');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _pickFile() async {
    if (!widget.requireTxt) return; // requireTxt가 false면 파일 선택 불필요

    setState(() {
      isLoading = true;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );

    if (result != null && result.files.single.path != null) {
      final selectedPath = result.files.single.path!;
      final extension = path.extension(selectedPath).toLowerCase();
      if (extension != '.txt') {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only TXT files are allowed.')),
        );
        return;
      }

      _filePath = selectedPath;

      final content = await _loadFileContent(_filePath!);
      if (content != null) {
        _generateSummary(content);
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read the TXT file.')),
        );
      }
    } else {
      print('No file selected.');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> _loadFileContent(String filePath) async {
    File file = File(filePath);

    if (await file.exists()) {
      try {
        String content = await file.readAsString();
        if (content.length > 4000) {
          content = content.substring(content.length - 4000);
        }
        return content;
      } catch (e) {
        print('Error reading file: $e');
        return null;
      }
    } else {
      print('File does not exist.');
      return null;
    }
  }

  Future<void> _generateSummary(String chattingText) async {
    setState(() {
      isLoading = true;
    });
    String result = await textSummarizer.summarize(chattingText);
    setState(() {
      summary = result;
      isLoading = false;
    });
  }

  void _onAddButtonPressed() {
    final trimmedName = name.trim();
    final trimmedRelationship = relationship.trim();

    if (trimmedName.isEmpty ||
        trimmedRelationship.isEmpty ||
        trimmedName.length != name.length ||
        trimmedRelationship.length != relationship.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Please enter the Name and Relationship fields without any spaces before and after. (Space between words allowed)'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Add'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSummaryRow('Name:', trimmedName),
                _buildSummaryRow('Relationship:', trimmedRelationship),
                _buildSummaryRow('Attitude:', attitude),
                // requireTxt가 true일 때만 Summary 표시
                if (widget.requireTxt) _buildSummaryRow('Summary:', summary),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(
                  context,
                  {
                    'name': trimmedName,
                    'relationship': trimmedRelationship,
                    'attitude': attitude,
                    'imagePath': _imagePath,
                    'summary': widget.requireTxt ? summary : '',
                  },
                );
              },
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.teal),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$title ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required String label, required Function(String) onChanged}) {
    List<TextInputFormatter> inputFormatters = [];
    inputFormatters.add(LengthLimitingTextInputFormatter(30));

    return TextField(
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: label == 'Name'
            ? const Icon(Icons.person)
            : const Icon(Icons.people),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      ),
    );
  }

  Widget _buildFilePicker() {
    if (!widget.requireTxt) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _pickFile,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(
                Icons.upload_file,
                color: Colors.teal,
                size: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _filePath != null
                      ? path.basename(_filePath!)
                      : 'Upload KakaoTalk File (TXT)',
                  style: TextStyle(
                    color: _filePath != null ? Colors.black : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isDropdownOpen = !isDropdownOpen;
            });
          },
          child: Container(
            padding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  attitude[0].toUpperCase() + attitude.substring(1),
                  style: const TextStyle(fontSize: 16),
                ),
                Icon(
                  isDropdownOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Container(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Column(
              children: <String>[
                'Positive',
                'Negative',
                'neutrality',
                'ferocity',
                'kind'
              ].map((String value) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      attitude = value;
                      isDropdownOpen = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 20.0),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value[0].toUpperCase() + value.substring(1),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          crossFadeState: isDropdownOpen
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
            'Add Assistant',
            style: TextStyle(
              fontWeight: FontWeight.w200,
              fontSize: 25,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text(
                            'Profile Image',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: _imagePath != null
                                      ? FileImage(File(_imagePath!))
                                      : null,
                                  child: _imagePath == null
                                      ? const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 60,
                                  )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 4,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.teal,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Name',
                    onChanged: (value) => name = value,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Relationship',
                    onChanged: (value) => relationship = value,
                  ),
                  const SizedBox(height: 16),
                  // requireTxt가 true일 때만 파일 피커 표시
                  if (widget.requireTxt) _buildFilePicker(),
                  const SizedBox(height: 16),
                  // requireTxt가 true이고 summary가 있을 때만 표시
                  if (widget.requireTxt && summary.isNotEmpty)
                    Card(
                      color: Colors.teal[50],
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Summary:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              summary,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildCustomDropdown(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _onAddButtonPressed,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.teal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TextSummarizer {
  Future<String> summarize(String text) async {
   // const apiKey = 'write your own API key';
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final prompt = 'Please summarize the text for about 4 lines using only English:\n$text';

    final response = await http.post(
      url,
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
      final summary = data['choices'][0]['message']['content'];
      return summary.trim();
    } else {
      print('Failed to get summary: ${response.body}');
      return 'Failed to generate summary.';
    }
  }
}
