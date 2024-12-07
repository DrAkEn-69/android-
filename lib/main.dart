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

  // Key to capture the widget for saving
  final GlobalKey imageKey = GlobalKey();

  String? text; // The text to overlay
  double fontSize = 24; // Default font size
  Offset textPosition = const Offset(50, 50); // Default text position
  String fontFamily = 'Roboto'; // Default font family

  // List of available fonts
  final List<String> fontOptions = [
    'Roboto',
    'Lobster',
    'Pacifico',
    'OpenSans',
    'Anton',
  ];

  Future<void> pickImage() async {
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      selectedImage = pickedImage;
    });
  }

  Future<void> saveToGallery() async {
    try {
      final boundary = imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save the image to a temporary directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/edited_image.png');
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save image')),
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
                    onPressed: saveToGallery,
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
            Row(
              children: [
                const Text("Font:"),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: fontFamily,
                    items: fontOptions.map((String font) {
                      return DropdownMenuItem(
                        value: font,
                        child: Text(font, style: TextStyle(fontFamily: font)),
                      );
                    }).toList(),
                    onChanged: (String? newFont) {
                      setState(() {
                        fontFamily = newFont!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}