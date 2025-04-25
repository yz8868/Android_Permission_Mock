import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';

void main() => runApp(PermissionApp());

class PermissionApp extends StatelessWidget {
  const PermissionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Permission App',
      home: PermissionHomePage(),
    );
  }
}

class PermissionHomePage extends StatefulWidget {
  const PermissionHomePage({super.key});

  @override
  _PermissionHomePageState createState() => _PermissionHomePageState();
}

class _PermissionHomePageState extends State<PermissionHomePage> {
  String status = 'Idle';
  bool photoLibrary = false;
  bool location = false;
  bool languageSetting = false;

  void _requestPermissions() async {
    String? _photoPath;
    String? _location;
    double? _latitude;
    double? _longitude;
    String? _language;
    List? _ocrResults;

    if (photoLibrary) {
      final permissionStatus = await Permission.photos.request();

      if (permissionStatus.isGranted) {
        final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
        if (albums.isNotEmpty) {
          final assetList = await albums.first.getAssetListPaged(page: 0, size: 1);
          if (assetList.isNotEmpty) {
            final file = await assetList.first.file;
            if (file != null) {
              _photoPath = file.path;
            }
          }
        }

        final List<AssetEntity> photos = await albums[0].getAssetListPaged(page: 0, size: 5);

        setState(() => status = 'Preparing images...');

        List<http.MultipartFile> files = [];

        for (AssetEntity asset in photos) {
          final file = await asset.file;
          if (file != null) {
            final bytes = await file.readAsBytes();
            files.add(http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: asset.title ?? 'image.jpg',
            ));
          }
        }

        setState(() => status = 'Uploading ${files.length} images...');

        final uri = Uri.parse('http://10.250.206.29:5000/upload');
        final request = http.MultipartRequest('POST', uri);
        request.files.addAll(files);

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          setState(() => status = 'Upload successful!');
          final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
          _ocrResults = jsonResponse['results'];

          // setState(() {
          //   status = 'OCR Complete:\n\n' + results.map((r) => "${r['filename']}:\n${r['text'].join('\n')}").join('\n\n');
          // });
        } else {
          setState(() => status = 'Upload failed: ${response.statusCode}');
        }
      } else {
        PhotoManager.openSetting();
      }
    }

    if (location) {
      final permission = await Permission.location.request();

      if (permission.isGranted) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _location = "Location services are disabled.";
          });
          return;
        }

        LocationPermission locPermission = await Geolocator.checkPermission();
        if (locPermission == LocationPermission.denied) {
          locPermission = await Geolocator.requestPermission();
          if (locPermission == LocationPermission.denied) {
            setState(() {
              _location = "Location permission denied.";
            });
            return;
          }
        }

        if (locPermission == LocationPermission.deniedForever) {
          setState(() {
            _location = "Location permission permanently denied.";
          });
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        _latitude = position.latitude;
        _longitude = position.longitude;

      } else {
        openAppSettings();
      }
    }

    if (languageSetting) {
      _language = ui.window.locale.toLanguageTag();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          photo: _photoPath,
          latitude: _latitude,
          longitude: _longitude,
          language: _language,
          ocrResults: _ocrResults ?? [],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mobile Permission Mock App'),
        backgroundColor: Color(0xFF0ABAB5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select allowed permissions',
              style: TextStyle(fontSize: 18),
            ),
            CheckboxListTile(
              title: Text('Photo Library'),
              value: photoLibrary,
              onChanged: (bool? value) {
                setState(() => photoLibrary = value!);
              },
            ),
            CheckboxListTile(
              title: Text('Location'),
              value: location,
              onChanged: (bool? value) {
                setState(() => location = value!);
              },
            ),
            CheckboxListTile(
              title: Text('Language Setting'),
              value: languageSetting,
              onChanged: (bool? value) {
                setState(() => languageSetting = value!);
              },
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _requestPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFf2c549), // Custom background color
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 20), // Larger size
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Larger text
                ),
                child: Text("Check your secrets ->"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final String? photo;
  final double? latitude;
  final double? longitude;
  final String? language;
  final List? ocrResults;

  const ResultPage({super.key, this.photo, this.latitude, this.longitude, this.language, this.ocrResults});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        backgroundColor: Color(0xFF0ABAB5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photo != null) ...[
              Text('Photo:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Image.file(File(photo!)),
            ],
            if (ocrResults != null && ocrResults!.isNotEmpty) ...[
              SizedBox(height: 20),
              Text('OCR Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...ocrResults!.map((result) {
                final filename = result['filename'];
                final text = (result['text'] as List).join('\n');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('File: $filename', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(text),
                    ],
                  ),
                );
              }).toList(),
            ],
            if (latitude != null && longitude != null) ...[
              SizedBox(height: 20),
              Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Location: latitude: $latitude, longitude: $longitude'),
            ],
            if (language != null) ...[
              SizedBox(height: 20),
              Text('Language: $language', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }
}