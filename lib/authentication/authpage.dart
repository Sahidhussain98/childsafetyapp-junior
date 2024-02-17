import 'package:flutter/material.dart';
import 'package:child_safety/insideapp/Login_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Always navigate to the login page
    return MyLogin();
  }
}
