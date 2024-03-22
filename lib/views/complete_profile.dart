import 'dart:developer';
import 'dart:io';

import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/views/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ignore: must_be_immutable
class CompleteProfileScreen extends StatefulWidget {
  UserModel? userModel;
  CompleteProfileScreen({super.key, this.userModel});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  XFile? pickedFile;

  TextEditingController fullNameController = TextEditingController();
  Future<void> showImageSourceDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:const Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Text('Camera'),
                  onTap: () async {
                    Navigator.pop(context);
                    pickedFile = (await ImagePicker()
                        .pickImage(source: ImageSource.camera))!;
                        setState(() {
                          
                        });
                  },
                ),
                GestureDetector(
                  child: const Text('Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    pickedFile = (await ImagePicker()
                        .pickImage(source: ImageSource.gallery))!;
                         setState(() {
                          
                        });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> uploadImageToFirestore() async {
 

  if (pickedFile != null) {
 
    File imageFile = File(pickedFile!.path);

 
    Reference storageReference = FirebaseStorage.instance.ref().child('images').child('${DateTime.now()}.jpg');
 
    UploadTask uploadTask = storageReference.putFile(imageFile);

    
    String imageUrl = await (await uploadTask).ref.getDownloadURL();

    widget.userModel!.fullName = fullNameController.text;
    widget.userModel!.profileImage = imageUrl;
    await FirebaseFirestore.instance.collection('users')
    .doc(widget.userModel!.uid).set(widget.userModel!.toJson());

  
    log('Image uploaded successfully!');
  } else {
    
    log('No image selected.');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: GestureDetector(
                onTap: () async {
                  await showImageSourceDialog(context);

                  setState(() {});
                },
                child: CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 70,
                  child: pickedFile != null
                      ? ClipOval(
                          child: Image.file(
                            File(pickedFile!.path),
                            fit: BoxFit.cover,
                            width: 140,
                            height: 140,
                          ),
                        )
                      :const Icon(
                          Icons.person,
                          color: Colors.black,
                        ),
                ),
              ),
            ),
             TextField(
              controller: fullNameController,
              decoration:const InputDecoration(hintText: "Full Name"),
            ),
            const SizedBox(
              height: 50,
            ),
            CupertinoButton(
                color: Colors.blue,
                child: const Text(
                  "Submit",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                 uploadImageToFirestore().then((value) {
                   Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()));
                 });
                }),
          ],
        ),
      ),
    );
  }
}
