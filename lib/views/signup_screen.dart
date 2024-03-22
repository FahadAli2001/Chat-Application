import 'dart:developer';

import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/views/complete_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> signUpWithEmailAndPassword(String email,String password)async{
    try {
      UserCredential userCredential =await 
    FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

    // ignore: unnecessary_null_comparison
    if (userCredential != null) {
      String uid = userCredential.user!.uid;
      UserModel newUser = UserModel(
        uid: uid,
        fullName: '',
        email: email,
        profileImage: ''
      );
      await FirebaseFirestore.instance.collection('users').doc(uid).set(newUser.toJson()).then((value) {
         Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>   CompleteProfileScreen(
                            userModel:newUser
                          )));
      });
    }
    } catch (e) {
      log(e.toString());
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
            const Text(
              "Chat App",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 22),
            ),
            const Text(
              "Sign Up ",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 22),
            ),
            const SizedBox(
              height: 50,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(hintText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(hintText: "Password"),
            ),
            const SizedBox(
              height: 50,
            ),
            CupertinoButton(
                color: Colors.blue,
                child: const Text(
                  "Sign Up",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                 signUpWithEmailAndPassword(emailController.text, passwordController.text);
                }),
            const SizedBox(
              height: 30,
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Login",
                style: TextStyle(color: Colors.blue, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
