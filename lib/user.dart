class User {
  final String id;
  final String username;
  late String picture;

  UserType get type => (id == "0")
      ? UserType.None
      : (id.contains("@"))
          ? UserType.Google
          : UserType.Discord;

  User(
      {required this.id,
      required this.username,
      //default profile picture is a bald doggo
      String avatar = ""}) {
    picture = avatar;
  }
}

enum UserType { None, Discord, Google }
