import 'dart:developer';
import 'dart:io';
import 'package:chatapp/views/view_file_screen.dart';
import 'package:file_picker/file_picker.dart';
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

  String? filePath;

  Future<String?> pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
        ],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        Reference storageReference =
            FirebaseStorage.instance.ref().child('files/$fileName');
        UploadTask uploadTask = storageReference.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        String downloadURL = await snapshot.ref.getDownloadURL();
        log('File uploaded. Download URL: $downloadURL');
        sendMessage(null, null, downloadURL);
        return downloadURL;
      } else {
        log('User canceled file picking.');
        return null;
      }
    } catch (e) {
      log('Error picking and uploading file: $e');
      return null;
    }
  }

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

  void sendMessage(
      [String? imageUrl, String? voiceNoteUrl, String? fileUrl]) async {
    String msg = messageController.text.trim();
    messageController.clear();

    if (msg != "" ||
        imageUrl != null ||
        voiceNoteUrl != null ||
        fileUrl != null) {
      MessageModel newMessage = MessageModel(
          messageId: uuid.v1(),
          sender: widget.userModel!.uid,
          createdOn: DateTime.now(),
          text: msg,
          seen: false,
          imageUrl: imageUrl,
          voiceNoteUrl: voiceNoteUrl,
          fileUrl: fileUrl);

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

  void deleteMessage(String messageId) async {
    try {
      final messageRef = FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(widget.chatRoomModel!.roomId)
          .collection("messages")
          .doc(messageId);
      await messageRef.delete();
      log('Message deleted successfully');
    } catch (e) {
      log('Error deleting message: $e');
    }
  }

  Future<Duration?> fetchVoiceNoteDuration(String? voiceNoteUrl) async {
    try {
      final player = AudioPlayer();
      await player.setUrl(voiceNoteUrl!);
      await player.load();
      final totalDuration = player.duration;
      await player.dispose();
      return totalDuration;
    } catch (e) {
      log("Error fetching voice note duration: $e");
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.targetUser!.fullName.toString()),
                Text(
                  widget.targetUser!.status.toString(),
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SizedBox(
          child: Column(
            children: [
              // This is where the chats will go
              Expanded(
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
                            MessageModel currentMessage = MessageModel.fromJson(
                                dataSnapshot.docs[index].data()
                                    as Map<String, dynamic>);

                            return InkWell(
                                onLongPress: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Delete Message'),
                                        content: const Text(
                                            'Are you sure you want to delete this message?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              deleteMessage(
                                                  currentMessage.messageId!);
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Row(
                                    mainAxisAlignment: (currentMessage.sender ==
                                            widget.userModel!.uid)
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    children: [
                                      if (currentMessage.text != null)
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            color: (currentMessage.sender ==
                                                    widget.userModel!.uid
                                                ? Colors.grey.shade200
                                                : Colors.blue[200]),
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                         
                                            children: [
                                            
                                              Text(
                                                currentMessage.text!,
                                                style: const TextStyle(
                                                    fontSize: 15),
                                              ),
                                                (currentMessage.sender ==
                                                          widget
                                                              .userModel!.uid &&
                                                      currentMessage.seen ==
                                                          true)
                                                  ? const Icon(Icons.done_all,
                                                      color: Colors.blue,
                                                      size: 18)
                                                  : const Icon(Icons.done,
                                                      color: Colors.grey,
                                                      size: 18),
                                            ],
                                          ),
                                        ),
                                      if (currentMessage.fileUrl != null)
                                        InkWell(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ViewFileScreen(
                                                        pdfUrl: currentMessage
                                                            .fileUrl!),
                                              ),
                                            );
                                          },
                                          child: Icon(
                                            Icons.file_copy,
                                            color: (currentMessage.sender ==
                                                    widget.userModel!.uid)
                                                ? Colors.grey
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                            size: 40,
                                          ),
                                        ),
                                      if (currentMessage.voiceNoteUrl != null)
                                        VoiceMessageView(
                                          circlesColor: Colors.blue,
                                          activeSliderColor: Colors.blue,
                                          controller: VoiceController(
                                            audioSrc: currentMessage
                                                .voiceNoteUrl
                                                .toString(),
                                            maxDuration: Duration.zero,
                                            isFile: false,
                                            onComplete: () {
                                              stopVoiceMessage();
                                            },
                                            onPause: () {
                                              pauseVoiceMessage();
                                            },
                                            onPlaying: () {
                                              playVoiceMessage(
                                                  currentMessage.voiceNoteUrl!);
                                            },
                                            onError: (err) {
                                              log(err.toString());
                                            },
                                          ),
                                        ),
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
                                    ]));
                          },
                        );
                      } else if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                              "An error occurred! Please check your internet connection."),
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
                                    pickAndUploadFile();
                                  },
                                  child: const Icon(
                                    Icons.file_copy_rounded,
                                    color: Colors.blue,
                                  )),
                              GestureDetector(
                                onTap: () {
                                  pickImage();
                                },
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 10),
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
