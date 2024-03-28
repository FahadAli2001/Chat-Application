class UserModel{
  String? uid;
  String? fullName;
  String? email;
  String? profileImage;
  String? status;
  bool? isInRoom;

  UserModel({
    this.uid,
    this.fullName,
    this.email,
    this.profileImage,
    this.status,
    this.isInRoom
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      fullName: json['fullName'],
      email: json['email'],
      profileImage: json['profileImage'],
      status: json['status'],
      isInRoom: json['isInRoom']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'profileImage': profileImage,
      'status':status,
      'isInRoom':isInRoom
    };
  }
}