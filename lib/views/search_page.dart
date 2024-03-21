import 'package:chatapp/main.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/views/chat_room_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/chat_room_model.dart';

// ignore: must_be_immutable
class SearchPage extends StatefulWidget {
  UserModel userModel;
  SearchPage({super.key, required this.userModel});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();

  Future<ChatRoomModel?> getChatRoomModel(UserModel targetUser) async {
    ChatRoomModel? chatRoom;
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('chatrooms')
        .where('participants.${widget.userModel.uid}', isEqualTo: true)
        .where('participants.${targetUser.uid}', isEqualTo: true)
        .get();

    if (snapshot.docs.length >0 ) {
      // fetch exsisting
      var docs = snapshot.docs[0].data();

      ChatRoomModel exsistingRoom =
          ChatRoomModel.fromJson(docs as Map<String, dynamic>  );

      chatRoom = exsistingRoom;
    } else {
      // create new one

      ChatRoomModel newChatRoomModel = ChatRoomModel(
          roomId: uuid.v1(),
          lastMessage: '',
          participants: {
            widget.userModel.uid.toString(): true,
            targetUser.uid.toString(): true
          });

      await FirebaseFirestore.instance
          .collection('chatrooms')
          .doc(newChatRoomModel.roomId)
          .set(newChatRoomModel.toJson());

      chatRoom = newChatRoomModel;
    }

    return chatRoom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(
              height: 70,
            ),
            TextField(
              controller: searchController,
              decoration: const InputDecoration(hintText: 'search here'),
            ),
            const SizedBox(
              height: 50,
            ),
            CupertinoButton(
                color: Colors.blue,
                child: const Text('search'),
                onPressed: () {
                  setState(() {});
                }),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: searchController.text)
                  .where('email', isNotEqualTo: widget.userModel.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                QuerySnapshot querySnapshot = snapshot.data as QuerySnapshot;

                if (querySnapshot.docs.isNotEmpty) {
                  Map<String, dynamic> userMap =
                      querySnapshot.docs[0].data() as Map<String, dynamic>;

                  UserModel searchUser = UserModel.fromJson(userMap);

                  return ListTile(
                    onTap: () async {
                      ChatRoomModel? chatRoomModel =
                          await getChatRoomModel(searchUser);
                      if (chatRoomModel != null) {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ChatRoomPage(
                                      targetUser: searchUser,
                                      userModel: widget.userModel,
                                      chatRoomModel: chatRoomModel,
                                    )));
                      }
                    },
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(searchUser.profileImage!),
                    ),
                    title: Text(searchUser.fullName.toString()),
                    subtitle: Text(searchUser.email.toString()),
                  );
                }
                return const Text('No User Found');
              },
            )
          ],
        ),
      ),
    );
  }
}
