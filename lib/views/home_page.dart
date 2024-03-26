import 'package:chatapp/controller/firebase_helper.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/views/chat_room_screen.dart';
import 'package:chatapp/views/login_screen.dart';
import 'package:chatapp/views/search_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/chat_room_model.dart';

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  UserModel userModel;
  HomePage({super.key, required this.userModel});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  FirebaseHelper firebaseHelper = FirebaseHelper();
  @override
  void dispose() {
    // Dispose the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // for app state
    WidgetsBinding.instance.addObserver(this);
    setUserStatus('online');
  }

  void setUserStatus(String status) async {
    widget.userModel.status = status;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userModel.uid)
        .set(widget.userModel.toJson());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // online
      setUserStatus('online');
    } else {
      // offline
      setUserStatus('offline');
    }
  }

Future<void> markMessagesAsSeen(
    ChatRoomModel chatRoomModel, String recipientId) async {
  CollectionReference messagesRef = FirebaseFirestore.instance
      .collection("chatrooms")
      .doc(chatRoomModel.roomId)
      .collection("messages");

  QuerySnapshot unseenMessagesSnapshot = await messagesRef
      .where('sender', isEqualTo: recipientId)
      .where('seen', isEqualTo: false)
      .get();

  unseenMessagesSnapshot.docs.forEach((messageDoc) async {
    await messageDoc.reference.update({
      'seen': true,
    });
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.blue,
            child: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return SearchPage(
                  userModel: widget.userModel,
                );
              }));
            }),
        appBar: AppBar(
          backgroundColor: Colors.blue,
          automaticallyImplyLeading: false,
          title: const Text(
            'ChatApp',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                FirebaseAuth.instance.signOut().then((value) {
                  setUserStatus('offline');
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) {
                    return const LoginScreen();
                  }));
                });
              },
              child: const Icon(
                Icons.login_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              width: 30,
            )
          ],
        ),
        body: SafeArea(
            child: SizedBox(
                child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("chatrooms")
                        .where("participants.${widget.userModel.uid}",
                            isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.hasData) {
                          QuerySnapshot chatRoomSnapshot =
                              snapshot.data as QuerySnapshot;

                          return ListView.builder(
                            itemCount: chatRoomSnapshot.docs.length,
                            itemBuilder: (context, index) {
                              ChatRoomModel chatRoomModel =
                                  ChatRoomModel.fromJson(
                                      chatRoomSnapshot.docs[index].data()
                                          as Map<String, dynamic>);

                              Map<String, dynamic> participants =
                                  chatRoomModel.participants!;

                              List<String> participantKeys =
                                  participants.keys.toList();
                              participantKeys.remove(widget.userModel.uid);

                              return FutureBuilder(
                                future: firebaseHelper
                                    .getUserModelById(participantKeys[0]),
                                builder: (context, userData) {
                                  if (userData.connectionState ==
                                      ConnectionState.done) {
                                    if (userData.data != null) {
                                      UserModel targetUser =
                                          userData.data as UserModel;

                                      return ListTile(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                              return ChatRoomPage(
                                                chatRoomModel: chatRoomModel,
                                                userModel: widget.userModel,
                                                targetUser: targetUser,
                                              );
                                            }),
                                          );
                                          markMessagesAsSeen(
                                              chatRoomModel, targetUser.uid!);
                                        },
                                        leading: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                              targetUser.profileImage
                                                  .toString()),
                                        ),
                                        trailing: CircleAvatar(
                                            radius: 10,
                                            backgroundColor:
                                                targetUser.status == 'online'
                                                    ? Colors.green
                                                    : Colors.grey),
                                        title: Text(
                                            targetUser.fullName.toString()),
                                        subtitle: (chatRoomModel.lastMessage
                                                    .toString() !=
                                                "")
                                            ? Text(chatRoomModel.lastMessage
                                                .toString())
                                            : Text(
                                                "Say hi to your new friend!",
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary,
                                                ),
                                              ),
                                      );
                                    } else {
                                      return Container();
                                    }
                                  } else {
                                    return Container();
                                  }
                                },
                              );
                            },
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(snapshot.error.toString()),
                          );
                        } else {
                          return const Center(
                            child: Text("No Chats"),
                          );
                        }
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    }))));
  }
}
