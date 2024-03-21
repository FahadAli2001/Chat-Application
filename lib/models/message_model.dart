class MessageModel {
  String? messageId;
  String? sender;
  String? text;
  bool? seen;
  DateTime? createdOn;

  MessageModel({
    this.sender,
    this.text,
    this.seen,
    this.createdOn,
    this.messageId
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      sender: json['sender'],
      text: json['text'],
      seen: json['seen'],
      createdOn: json['createdOn'].toDate()  ,
      messageId:json['messageId']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'text': text,
      'seen': seen,
      'createdOn': createdOn,
      'messageId':messageId
    };
  }
}
