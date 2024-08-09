import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class UserImage extends StatefulWidget {
  final Function(String imgUri) onFileChanged;

  const UserImage({super.key, required this.onFileChanged});

  @override
  State<UserImage> createState() => _UserImageState();
}

class _UserImageState extends State<UserImage> {
  final ImagePicker _picker = ImagePicker();
  String? imgUri;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (imgUri == null)
          Icon(
            Icons.image,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
        if (imgUri != null)
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () => _selectPhoto(),
            child: CircleAvatar(
              backgroundImage: NetworkImage(imgUri!),
              radius: 40,
            ),
          ),
        InkWell(
          onTap: () => _selectPhoto(),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              imgUri != null ? "Change Photo" : "Upload Photo",
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future _selectPhoto() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => BottomSheet(
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text("Camera"),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Pick a Photo"),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
        onClosing: () {},
      ),
    );
  }

  Future _pickImage(ImageSource source) async {
    final pickedFile =
        await _picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile == null) {
      return;
    }

    var file = await ImageCropper.platform.cropImage(
      sourcePath: pickedFile.path,
      maxWidth: null,
      maxHeight: null,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: null,
    );

    if (file == null) {
      return;
    }

    file = (await compressImage(file.path, 35)) as CroppedFile?;
    await _uploadImage(file!.path);
  }

  Future<XFile> compressImage(String path, int quality) async {
    final newPath = p.join(
      (await getTemporaryDirectory()).path,
      '${DateTime.now().millisecondsSinceEpoch}${p.extension(path)}',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      path,
      newPath,
      quality: quality,
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    return result;
  }

  Future _uploadImage(String path) async {
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child("user_images")
          .child("${DateTime.now().toIso8601String()}_${p.basename(path)}");

      final result = await ref.putFile(File(path));
      final fileUri = await result.ref.getDownloadURL();

      setState(() {
        imgUri = fileUri;
      });

      widget.onFileChanged(fileUri);
    } catch (e) {
      print('Upload failed: $e');
    }
  }
}
