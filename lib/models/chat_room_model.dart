class ChatRoomModel {
  String? roomId;
  Map<String, dynamic>? participants;
  String? lastMessage;
  

  ChatRoomModel({
    this.roomId,
    this.participants,
    this.lastMessage,
  
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      roomId: json['roomId'],
      participants: json['participants'],
      lastMessage: json['lastMessage'],
     
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'participants': participants,
  
    };
  }
}
