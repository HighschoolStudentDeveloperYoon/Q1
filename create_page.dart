import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreatePage extends StatefulWidget {
  final FirebaseUser user;

  CreatePage(this.user);

  @override
  _CreatePageState createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getImage();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  File _image;

  // 갤러리에서 사진 가져오기
  Future _getImage() async {
    var image = await ImagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 640,
      maxHeight: 480,
    );

    setState(() {
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('게시물 업로드',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      actions: <Widget>[
        FlatButton(
          onPressed: () {
            _uploadFile(context);
          },
          child: Text('공유'),
        )
      ],
    );
  }

  Future _uploadFile(BuildContext context) async {
    // 스토리지에 업로드할 파일 경로
    final firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child('post')
        .child('${DateTime.now().millisecondsSinceEpoch}.png');

    // 파일 업로드
    final task = firebaseStorageRef.putFile(
      _image,
      StorageMetadata(contentType: 'image/png'),
    );

    // 완료까지 기다림
    final storageTaskSnapshot = await task.onComplete;

    // 업로드 완료 후 url
    final downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();

    // 문서 작성
    await Firestore.instance.collection('post').add(
        {
          'contents': textEditingController.text,
          'displayName': widget.user.displayName,
          'email': widget.user.email,
          'photoUrl': downloadUrl,
          'userPhotoUrl': widget.user.photoUrl,
        }
    );

    // 완료 후 앞 화면으로 이동
    Navigator.pop(context);
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                _buildImage(),
                SizedBox(
                  width: 8.0,
                ),
                Expanded(
                  child: TextField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: '문구를 입력하세요',
                    ),
                  ),
                )
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildImage() {
    return _image == null
        ? Text('No Image')
        : Image.file(
      _image,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
    );
  }
}