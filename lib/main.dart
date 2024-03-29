import 'package:chatapp/controller/firebase_helper.dart';
import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/views/home_page.dart';
import 'package:chatapp/views/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_channel/flutter_notification_channel.dart';
import 'package:flutter_notification_channel/notification_importance.dart';
import 'package:uuid/uuid.dart';


var uuid =const Uuid();

void main()async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform);
   await FlutterNotificationChannel().registerNotificationChannel(
    description: 'For showing messages',
    id: 'chats',
    importance: NotificationImportance.IMPORTANCE_HIGH,
    name: 'Chats',
    
);
 
 
  User? user = FirebaseAuth.instance.currentUser;
   // ignore: unused_local_variable
   FirebaseHelper firebaseHelper = FirebaseHelper();
  if (user!=null) {
    UserModel? userModel =await firebaseHelper.getUserModelById(user.uid) ;
    runApp(MyAppLoggedIn(
      userModel:userModel,
    ));
  } else {
    
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
         
        
        useMaterial3: true,
      ),
      home:const LoginScreen(),
    );
  }
}

// ignore: must_be_immutable
class MyAppLoggedIn extends StatelessWidget {
  UserModel? userModel;
    MyAppLoggedIn({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
         
        
        useMaterial3: true,
      ),
      home:  HomePage(
        userModel: userModel!,
      ),
    );
  }
}


 