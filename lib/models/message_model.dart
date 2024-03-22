 class MessageModel {
  String? messageId;
  String? sender;
  String? text;
  bool? seen;
  DateTime? createdOn;
  String? imageUrl;
  String? voiceNoteUrl; // Add voiceNoteUrl field for storing voice note URL

  MessageModel({
    this.sender,
    this.text,
    this.seen,
    this.createdOn,
    this.messageId,
    this.imageUrl,
    this.voiceNoteUrl, // Update constructor to accept voiceNoteUrl
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      sender: json['sender'],
      text: json['text'],
      seen: json['seen'],
      createdOn: json['createdOn'].toDate(),
      messageId: json['messageId'],
      imageUrl: json['imageUrl'],
      voiceNoteUrl: json['voiceNoteUrl'], // Update to include voiceNoteUrl
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
      'voiceNoteUrl': voiceNoteUrl, // Update to include voiceNoteUrl
    };
  }
}
