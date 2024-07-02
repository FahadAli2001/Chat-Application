import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:chatapp/controller/firebase_helper.dart';
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
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class ChatRoomPage extends StatefulWidget {
  UserModel? targetUser;
  final ChatRoomModel? chatRoomModel;
  final UserModel? userModel;
  ChatRoomPage({
    super.key,
    this.targetUser,
    this.chatRoomModel,
    this.userModel,
  });

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
  FirebaseHelper firebaseHelper = FirebaseHelper();

  Future<void> sendPushNotifications(MessageModel messageModel) async {
    try {
      var Url = Uri.parse('https://fcm.googleapis.com/fcm/send');
      var body = {
        "to": widget.targetUser!.fToken,
        'priority': 'high',
        "notification": {
          "title": widget.userModel!.fullName,
          "body": messageModel.text,
          "android_channel_id": "chats",
          "sound": "default"
        }
      };

      var response = await http.post(Url,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader:
                'key=AAAAQaZnRKE:APA91bF6SPMsbG21V4RUQQpPhtrKbLiT6kgm1N09ty3bANghIE4yf9HK_KMxADa8Je25at3i_W74t-Xw7emb03jBM41FDS_aUw4G09mCGuY-nO1F3N0DN1dfNvNpaNO832JHSw99FXfA'
          },
          body: jsonEncode(body));
      if (response.statusCode == 200) {
        log('notification send');
      } else {
        log('notification not send');
      }
    } catch (e) {
      log("firebase push notification error : $e");
    }
  }

  void listenForMessageChanges() async {
    try {
      // Fetch real-time data from the user collection
      QuerySnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: widget.userModel!.uid)
          .get();

      var userDataMap = userData.docs.first.data() as Map<String, dynamic>;

      bool up = userDataMap['isInRoom'];
      log('User isInRoom: $up');

      QuerySnapshot targetData = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: widget.targetUser!.uid)
          .get();

      var targetDatamAP = targetData.docs.first.data() as Map<String, dynamic>;

      bool tp = targetDatamAP['isInRoom'];
      log('Target isInRoom: $tp');

      if (up && tp) {
        // Simplify condition, as up and tp are already boolean
        // Send the message
        sendMessage();

        // Listen for message changes and set 'seen' flag to true
        FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(widget.chatRoomModel!.roomId)
            .collection("messages")
            .get()
            .then((snapshot) {
          snapshot.docs.forEach((messageDoc) async {
            await messageDoc.reference.update({'seen': true});
          });
        });
      } else {
        log('false--');
        
        sendMessage(); // Only send the message when conditions are not met
      }
    } catch (e) {
      log(e.toString());
    }
  }

  // void listenForMessageChanges() async {
  //   // Fetch real-time data from the user collection
  //   QuerySnapshot userData = await FirebaseFirestore.instance
  //       .collection('users')
  //       .where('uid', isEqualTo: widget.userModel!.uid)
  //       .get();

  //   var userDataMap = userData.docs.first.data() as Map<String, dynamic>;

  //   bool up = userDataMap['isInRoom'];
  //   log(up.toString());
  //   log('----------');
  //   QuerySnapshot targetData = await FirebaseFirestore.instance
  //       .collection('users')
  //       .where('uid', isEqualTo: widget.targetUser!.uid)
  //       .get();

  //   var targetDatamAP = targetData.docs.first.data() as Map<String, dynamic>;

  //   bool tp = targetDatamAP['isInRoom'];
  //   log(tp.toString());

  //   if (up == true && tp == true) {
  //     log('true---');

  //      FirebaseFirestore.instance
  //       .collection("chatrooms")
  //       .doc(widget.chatRoomModel!.roomId)
  //       .collection("messages")
  //       .snapshots()
  //       .listen((QuerySnapshot snapshot) {
  //     snapshot.docs.forEach((messageDoc) async {
  //       await messageDoc.reference.update({
  //         'seen': true,
  //       });
  //     });

  //   });
  //    sendMessage();
  //   } else {
  //     log('false--');
  //     sendMessage();
  //   }
  // }

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
        sendMessage(null, null, downloadURL, 'file');
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

      sendMessage(null, audioUrl, null, 'voice');
    } catch (e) {
      log("Error uploading voice note: $e");
    }
  }

  void sendMessage([
    String? imageUrl,
    String? voiceNoteUrl,
    String? fileUrl,
    String? messageType,
  ]) async {
    String msg = messageController.text.trim();
    messageController.clear();

    if (msg.isNotEmpty ||
        imageUrl != null ||
        voiceNoteUrl != null ||
        fileUrl != null) {
      String? textToSend;
      if (messageType == "voice") {
        textToSend = "Voice Message";
      } else if (messageType == "file") {
        textToSend = "File ";
      } else if (messageType == "image") {
        textToSend = "Image ";
      } else {
        textToSend = msg;
      }

      MessageModel newMessage = MessageModel(
        messageId: uuid.v1(),
        sender: widget.userModel!.uid,
        createdOn: DateTime.now().microsecondsSinceEpoch,
        text: textToSend,
        seen: false, // Set seen to false for new messages
        imageUrl: imageUrl,
        voiceNoteUrl: voiceNoteUrl,
        fileUrl: fileUrl,
      );

      try {
        await FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(widget.chatRoomModel!.roomId)
            .collection("messages")
            .doc(newMessage.messageId)
            .set(newMessage.toJson())
            .then((value) {
          sendPushNotifications(newMessage);
        });

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

    sendMessage(imageUrl, null, null, 'image');
  }

  void setUserPresent() async {
    widget.userModel!.isInRoom = false;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userModel!.uid!)
        .set(widget.userModel!.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
            onTap: () {
              setUserPresent();
              Navigator.pop(context);
              log('${widget.userModel!.isInRoom!} current user');
              log('${widget.targetUser!.isInRoom!} target user');
            },
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            )),
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
                                  as Map<String, dynamic>,
                            );

                            bool isCurrentUserMessage =
                                currentMessage.sender == widget.userModel!.uid;

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
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: isCurrentUserMessage
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: isCurrentUserMessage
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                      children: [
                                        if (!isCurrentUserMessage)
                                          SizedBox(
                                            width: 48, // Adjust as needed
                                          ),
                                        Flexible(
                                          child: Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isCurrentUserMessage
                                                  ? Colors.blue.shade100
                                                  : Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              currentMessage.text!,
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ),
                                        if (isCurrentUserMessage)
                                          SizedBox(
                                            width: 48, // Adjust as needed
                                          ),
                                      ],
                                    ),
                                    if (currentMessage.fileUrl != null)
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ViewFileScreen(
                                                pdfUrl: currentMessage.fileUrl!,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Icon(
                                          Icons.file_copy,
                                          color: isCurrentUserMessage
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
                                          audioSrc: currentMessage.voiceNoteUrl
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
                                    if (isCurrentUserMessage)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Icon(
                                          currentMessage.seen == true
                                              ? Icons.done_all
                                              : Icons.done,
                                          color: currentMessage.seen == true
                                              ? Colors.blue
                                              : Colors.black,
                                          size: 18,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
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

              // for textfield
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
                        //  sendMessage();
                        listenForMessageChanges();
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
