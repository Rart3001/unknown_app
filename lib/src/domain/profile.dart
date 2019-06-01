import 'dart:convert';

Profile profileFromJson(String str) => Profile.fromJson(json.decode(str));

String profileToJson(Profile data) => json.encode(data.toJson());

class Profile {
  String name;
  String profile;
  String company;
  String mail;
  String img;

  Profile({
    this.name,
    this.profile,
    this.company,
    this.mail,
    this.img,
  });


  Profile.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        profile = json['profile'],
        company = json['company'],
        mail = json['mail'],
        img = json['img'];

  Map<String, dynamic> toJson() =>
      {
        'name': name,
        'profile': profile,
        'company': company,
        'mail': mail,
        'img': img,
      };
}