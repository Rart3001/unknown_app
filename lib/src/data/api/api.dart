import 'dart:async';
import 'dart:convert';
import 'package:unknown_app/src/domain/profile.dart';
import 'package:http/http.dart' as http;


class Api {

  static const API_URL = "http://13.58.161.135/api/v1/";

  Future<Profile> getProfile(final String name) async {
    final response = await http.get('$API_URL?name=$name');
    if (response.statusCode == 200) {
      print("response = ${response.body}");
      return profileFromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load profile');
    }
  }

}