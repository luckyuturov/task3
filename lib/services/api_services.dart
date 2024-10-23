import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart'; // Импортируем MediaType
import 'api_endpoints.dart';

class ApiService {
  Future<void> sendData({
    required String comment,
    required File imageFile,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Определяем MIME-тип файла
      final mimeType = lookupMimeType(imageFile.path) ?? 'application/octet-stream';
      final fileName = basename(imageFile.path);

      // Разделяем MIME-тип на тип и подтип
      final mimeTypeData = mimeType.split('/');

      // Формируем multipart запрос
      var request = http.MultipartRequest('POST', Uri.parse(ApiEndpoints.sendData))
        ..fields['comment'] = comment
        ..fields['latitude'] = latitude.toString()
        ..fields['longitude'] = longitude.toString()
        ..files.add(
          await http.MultipartFile.fromPath(
            'photo',
            imageFile.path,
            contentType: MediaType(mimeTypeData[0], mimeTypeData[1]), // Используем MediaType
            filename: fileName,
          ),
        );

      // Отправляем запрос
      var response = await request.send();

      if (response.statusCode == 200) {
        print('Upload successful');
      } else {
        print('Failed to upload data');
      }
    } catch (e) {
      print('Error uploading data: $e');
    }
  }
}
