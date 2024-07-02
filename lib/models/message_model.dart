class MessageModel {
  String? messageId;
  String? sender;
  String? text;
  bool? seen; 
  int? createdOn;
  String? imageUrl;
  String? voiceNoteUrl;
  String? fileUrl;  
 

  MessageModel({
    this.sender,
    this.text,
    this.seen,
    this.createdOn,
    this.messageId,
    this.imageUrl,
    this.voiceNoteUrl,
    this.fileUrl, 
 
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      sender: json['sender'],
      text: json['text'],
      seen: json['seen'],
      createdOn: json['createdOn'].toDate(),
      messageId: json['messageId'],
      imageUrl: json['imageUrl'],
      voiceNoteUrl: json['voiceNoteUrl'],
      fileUrl: json['fileUrl'], 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'text': text,
      'seen': seen,
      'createdOn': createdOn,
      'messageId': messageId,
      'imageUrl': imageUrl,
      'voiceNoteUrl': voiceNoteUrl,
      'fileUrl': fileUrl,  
    };
  }
}
