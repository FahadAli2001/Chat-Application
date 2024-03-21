import 'package:chatapp/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 
class FirebaseHelper{


   Future<UserModel> getUserModelById(String uid)async{
    UserModel userModel;

    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.collection('users')
    .doc(uid).get();

    userModel = UserModel.fromJson(documentSnapshot.data() as Map<String,dynamic>);

    return userModel;
  }
}