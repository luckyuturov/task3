import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'services/api_services.dart';
import 'services/location_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? cameraController;
  File? imageFile;
  TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await cameraController?.initialize();
    setState(() {});
  }

  Future<void> _captureAndSendData() async {
    if (cameraController != null && cameraController!.value.isInitialized && commentController.text.isNotEmpty) {
      try {
        // Захват изображения
        final image = await cameraController?.takePicture();
        if (image != null) {
          setState(() {
            imageFile = File(image.path);
          });

          // Получаем геолокацию
          Position position = await LocationService().getCurrentLocation();

          // Отправляем данные на сервер
          await ApiService().sendData(
            comment: commentController.text,
            imageFile: imageFile!,
            latitude: position.latitude,
            longitude: position.longitude,
          );

          // Показываем успешное сообщение
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data sent successfully')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing or sending data: $e')),
        );
      }
    } else {
      // Показываем сообщение, если комментарий не заполнен
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment before sending')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture and Send Data'),
      ),
      body: Column(
        children: [
          // Превью камеры
          if (cameraController != null && cameraController!.value.isInitialized)
            AspectRatio(
              aspectRatio: cameraController!.value.aspectRatio,
              child: CameraPreview(cameraController!),
            ),
          const SizedBox(height: 20),
          // Поле для ввода комментария
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Enter your comment',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Кнопка для отправки данных
          ElevatedButton(
            onPressed: _captureAndSendData,
            child: const Text('Send Data'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    commentController.dispose();
    super.dispose();
  }
}
