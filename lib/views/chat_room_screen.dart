import 'dart:developer';
import 'dart:io';

import 'package:chatapp/main.dart';
import 'package:chatapp/models/chat_room_model.dart';
import 'package:chatapp/models/message_model.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatRoomPage extends StatefulWidget {
  final UserModel? targetUser;
  final ChatRoomModel? chatRoomModel;
  final UserModel? userModel;
  const ChatRoomPage(
      {super.key, this.targetUser, this.chatRoomModel, this.userModel});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  TextEditingController messageController = TextEditingController();

  // void sendMessage() async {
  //   String msg = messageController.text.trim();
  //   messageController.clear();

  //   if (msg != "") {
  //     // Send Message
  //     MessageModel newMessage = MessageModel(
  //         messageId: uuid.v1(),
  //         sender: widget.userModel!.uid,
  //         createdOn: DateTime.now(),
  //         text: msg,
  //         seen: false);

  //     FirebaseFirestore.instance
  //         .collection("chatrooms")
  //         .doc(widget.chatRoomModel!.roomId)
  //         .collection("messages")
  //         .doc(newMessage.messageId)
  //         .set(newMessage.toJson());

  //     widget.chatRoomModel!.lastMessage = msg;
  //     FirebaseFirestore.instance
  //         .collection("chatrooms")
  //         .doc(widget.chatRoomModel!.roomId)
  //         .set(widget.chatRoomModel!.toJson());

  //     log("Message Sent!");
  //   }
  // }

  void sendMessage([String? imageUrl]) async {
    String msg = messageController.text.trim();
    messageController.clear();

    if (msg != "" || imageUrl != null) {
      // Send Message
      MessageModel newMessage = MessageModel(
        messageId: uuid.v1(),
        sender: widget.userModel!.uid,
        createdOn: DateTime.now(),
        text: msg,
        seen: false,
        imageUrl: imageUrl, // Add the imageUrl to the message model
      );

      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatRoomModel!.roomId)
          .collection("messages")
          .doc(newMessage.messageId)
          .set(newMessage.toJson());

      widget.chatRoomModel!.lastMessage = msg;
      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatRoomModel!.roomId)
          .set(widget.chatRoomModel!.toJson());

      log("Message Sent!");
    }
  }

  void pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      uploadImage(File(pickedImage.path));
    }
  }

  void uploadImage(File imageFile) async {
    var reference =
        FirebaseStorage.instance.ref().child('chat_images/${Uuid().v1()}');

    var uploadTask = reference.putFile(imageFile);

    var imageUrl = await uploadTask.then((taskSnapshot) {
      return taskSnapshot.ref.getDownloadURL();
    });

    sendMessage(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  NetworkImage(widget.targetUser!.profileImage.toString()),
            ),
            const SizedBox(
              width: 10,
            ),
            Text(widget.targetUser!.fullName.toString()),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              // This is where the chats will go
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("chatrooms")
                        .doc(widget.chatRoomModel!.roomId)
                        .collection("messages")
                        .orderBy("createdOn", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.active) {
                        if (snapshot.hasData) {
                          QuerySnapshot dataSnapshot =
                              snapshot.data as QuerySnapshot;

                          return ListView.builder(
                            reverse: true,
                            itemCount: dataSnapshot.docs.length,
                            itemBuilder: (context, index) {
                              MessageModel currentMessage =
                                  MessageModel.fromJson(dataSnapshot.docs[index]
                                      .data() as Map<String, dynamic>);

                              return Row(
                                mainAxisAlignment: (currentMessage.sender ==
                                        widget.userModel!.uid)
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (currentMessage.imageUrl !=
                                      null) // Check if message contains an image URL
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Image.network(
                                        currentMessage.imageUrl!,
                                        width:
                                            150, // Adjust the width according to your needs
                                        height:
                                            150, // Adjust the height according to your needs
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  if (currentMessage.text !=
                                      null) // Check if message contains text
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (currentMessage.sender ==
                                                widget.userModel!.uid)
                                            ? Colors.grey
                                            : Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        currentMessage.text!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        } else if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                                "An error occured! Please check your internet connection."),
                          );
                        } else {
                          return const Center(
                            child: Text("Say hi to your new friend"),
                          );
                        }
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  ),
                ),
              ),

              Container(
                color: Colors.grey[200],
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Row(
                  children: [
                    Flexible(
                      child: TextField(
                        controller: messageController,
                        maxLines: null,
                        decoration: InputDecoration(
                            suffixIcon: GestureDetector(
                                onTap: () {},
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.blue,
                                )),
                            border: InputBorder.none,
                            hintText: "Enter message"),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        sendMessage();
                      },
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
