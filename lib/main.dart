import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImageEditor(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ImageEditor extends StatefulWidget {
  const ImageEditor({super.key});

  @override
  State<ImageEditor> createState() => _ImageEditorState();
}

class _ImageEditorState extends State<ImageEditor> {
  final ImagePicker picker = ImagePicker();
  XFile? selectedImage;

  final GlobalKey imageKey = GlobalKey();

  String? text; // The text to overlay
  double fontSize = 24;
  Offset textPosition = const Offset(50, 50);
  String fontFamily = 'Roboto';

  Future<void> pickImage() async {
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      selectedImage = pickedImage;
    });
  }

  Future<void> saveToGallery() async {
    try {
      // Capture the image
      final boundary = imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get the app's internal directory
      final Directory appDir = await getApplicationDocumentsDirectory();

      // Create the custom directory
      final String dirPath = '${appDir.path}/images/meme-editor';
      await Directory(dirPath).create(recursive: true);

      // Generate a unique filename
      final String fileName = 'meme_${DateTime.now().millisecondsSinceEpoch}.png';
      final String filePath = '$dirPath/$fileName';

      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to $filePath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save image: ${e.toString()}')),
      );
    }
  }

  void updateTextPosition(DragUpdateDetails details) {
    setState(() {
      textPosition = Offset(
        textPosition.dx + details.delta.dx,
        textPosition.dy + details.delta.dy,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Meme Editor",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: selectedImage == null
                    ? const Text(
                  "No Image Selected",
                  style: TextStyle(fontSize: 18),
                )
                    : RepaintBoundary(
                  key: imageKey,
                  child: Stack(
                    children: [
                      Image.file(
                        File(selectedImage!.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      if (text != null)
                        Positioned(
                          left: textPosition.dx,
                          top: textPosition.dy,
                          child: GestureDetector(
                            onPanUpdate: updateTextPosition,
                            child: Text(
                              text!,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontFamily: fontFamily,
                                color: Colors.black,
                                backgroundColor: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text(
                      "Select Image",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.cyan,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await saveToGallery();
                    },
                    icon: const Icon(Icons.save),
                    label: const Text(
                      "Save to Gallery",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              onChanged: (value) => setState(() => text = value),
              decoration: const InputDecoration(
                hintText: "Enter text",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Font Size:"),
                Expanded(
                  child: Slider(
                    value: fontSize,
                    min: 12,
                    max: 72,
                    divisions: 6,
                    label: fontSize.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        fontSize = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

