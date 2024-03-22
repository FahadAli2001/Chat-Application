import 'dart:developer';
import 'dart:io';
import 'package:record/record.dart';
 import 'package:chatapp/main.dart';
import 'package:chatapp/models/chat_room_model.dart';
import 'package:chatapp/models/message_model.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:full_screen_image/full_screen_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voice_message_package/voice_message_package.dart';
import 'package:just_audio/just_audio.dart';

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
  final record = AudioRecorder();
  late AudioPlayer audioPlayer;
  late String recordedFilePath;
  int? duration;

  bool isRecording = false;

  Future<void> startRecording() async {
    try {
      if (await record.hasPermission()) {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String appDocPath = appDocDir.path;
        recordedFilePath =
            '$appDocPath/${DateTime.now().millisecondsSinceEpoch}.m4a';
        await record.start(const RecordConfig(), path: recordedFilePath);
      } else {
        log("Permission denied");
      }
    } catch (e) {
      log("Error starting recording: $e");
    }
  }

  void stopRecording() async {
    try {
      await record.stop();

      File audioFile = File(recordedFilePath);

      uploadVoiceNote(audioFile);
    } catch (e) {
      log("Error stopping recording: $e");
    }
  }

  void uploadVoiceNote(File audioFile) async {
    try {
      var reference =
          FirebaseStorage.instance.ref().child('chat_images/${uuid.v1()}');

      var uploadTask = reference.putFile(audioFile);

      var audioUrl = await uploadTask.then((taskSnapshot) {
        return taskSnapshot.ref.getDownloadURL();
      });

      sendMessage(null, audioUrl);
    } catch (e) {
      log("Error uploading voice note: $e");
    }
  }

  void sendMessage([String? imageUrl, String? voiceNoteUrl]) async {
    String msg = messageController.text.trim();
    messageController.clear();

    if (msg != "" || imageUrl != null || voiceNoteUrl != null) {
      // Send Message
      MessageModel newMessage = MessageModel(
        messageId: uuid.v1(),
        sender: widget.userModel!.uid,
        createdOn: DateTime.now(),
        text: msg,
        seen: false,
        imageUrl: imageUrl,
        voiceNoteUrl: voiceNoteUrl,
      );

      try {
        await FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(widget.chatRoomModel!.roomId)
            .collection("messages")
            .doc(newMessage.messageId)
            .set(newMessage.toJson());

        widget.chatRoomModel!.lastMessage = msg;
        await FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(widget.chatRoomModel!.roomId)
            .set(widget.chatRoomModel!.toJson());

        log("Message Sent!");
      } catch (e) {
        log("Error sending message: $e");
      }
    }
  }
 
 

Future<Duration?> fetchVoiceNoteDuration(String? voiceNoteUrl) async {
  try {
    final player = AudioPlayer();
    await player.setUrl(voiceNoteUrl!); // Set the URL of the audio file
    await player.load(); // Load the audio file
    final totalDuration = player.duration; // Get the duration of the audio file
    await player.dispose(); // Dispose the player when done
    return totalDuration;
  } catch (e) {
    print("Error fetching voice note duration: $e");
    return null;
  }
}

void playVoiceMessage(String voiceNoteUrl) {
  audioPlayer.setUrl(voiceNoteUrl);
  audioPlayer.play();
  log('Playing voice message');
}



void pauseVoiceMessage() {
  audioPlayer.pause();
  log('Voice message paused');
}

void stopVoiceMessage() {
  audioPlayer.stop();
  log('Voice message stopped');
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
        FirebaseStorage.instance.ref().child('chat_images/${uuid.v1()}');

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
        child: SizedBox(
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
                                 fetchVoiceNoteDuration(currentMessage.voiceNoteUrl)
                              .then((value){
                                duration = value!.inMilliseconds;
                              } );
                              return Row(
                                mainAxisAlignment: (currentMessage.sender ==
                                        widget.userModel!.uid)
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  if (currentMessage.imageUrl != null)
                                    FullScreenWidget(
                                      disposeLevel: DisposeLevel.Medium,
                                      child: Image.network(
                                        currentMessage.imageUrl!,
                                        width: 200,
                                        height: 300,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  if (currentMessage.voiceNoteUrl != null)
                                    
                                    VoiceMessageView(
                                      circlesColor: Colors.blue,
                                      activeSliderColor: Colors.blue,
                                      controller: VoiceController(
                                        audioSrc: currentMessage.voiceNoteUrl.toString(),
                                       maxDuration: duration != null ? Duration(seconds: duration!) : Duration.zero,

                                        isFile: false,
                                        onComplete: () {
                                          stopVoiceMessage();
                                        },
                                        onPause: () { 
                                          pauseVoiceMessage();
                                        },
                                        onPlaying: () {
                                          playVoiceMessage(currentMessage.voiceNoteUrl!);
                                        },
                                        onError: (err) {
                                          log(err.toString());
                                        },
                                      ),
                                    ),
                                  if (currentMessage.text != null)
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 10),
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
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  pickImage();
                                },
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(
                                  width: 10), // Add some spacing between icons
                              GestureDetector(
                                onLongPress: () {
                                  startRecording();

                                  setState(() {
                                    isRecording = true;
                                  });
                                },
                                onLongPressEnd: (details) {
                                  stopRecording();

                                  setState(() {
                                    isRecording = false;
                                  });
                                },
                                child: Icon(
                                  isRecording ? Icons.stop_circle : Icons.mic,
                                  color: isRecording ? Colors.red : Colors.blue,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                          border: InputBorder.none,
                          hintText: "Enter message",
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        sendMessage();
                      },
                      icon: const Icon(
                        Icons.send,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
