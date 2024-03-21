class MessageModel {
  String? messageId;
  String? sender;
  String? text;
  bool? seen;
  DateTime? createdOn;
  String? imageUrl; // Add imageUrl field for storing image URL

  MessageModel({
    this.sender,
    this.text,
    this.seen,
    this.createdOn,
    this.messageId,
    this.imageUrl, // Update constructor to accept imageUrl
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      sender: json['sender'],
      text: json['text'],
      seen: json['seen'],
      createdOn: json['createdOn'].toDate(),
      messageId: json['messageId'],
      imageUrl: json['imageUrl'],  
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
    };
  }
}

 