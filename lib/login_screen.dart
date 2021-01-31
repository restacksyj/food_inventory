import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:food_inventory/main.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:sign_button/sign_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class LoginScreen extends StatelessWidget {
  final storage = FlutterSecureStorage();
  
  Future<User> googleSignin() async {
    User currentUser;
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();
      print(googleUser.toString());
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final auth = await FirebaseAuth.instance.signInWithCredential(credential);
      assert(auth.user.email != null);
      assert(auth.user.displayName != null);
      assert(!auth.user.isAnonymous);
      assert(await auth.user.getIdToken() != null);
      currentUser = FirebaseAuth.instance.currentUser;
      assert(auth.user.uid == currentUser.uid);
      savePrefs(auth.user.uid);

      if (await storage.read(key: auth.user.uid) != "true") {
        setKeyIV();
      }

      Get.offAll(HomeScreen(), transition: Transition.cupertino);
    } catch (e) {
      print(e);
      return currentUser;
    }
  }

  savePrefs(String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("authId", value);
  }

  setKeyIV() async {
    final key = encrypt.Key.fromSecureRandom(32);
    final iv = encrypt.IV.fromLength(16);
    final prefs = await SharedPreferences.getInstance();


    await storage.write(key: "encryptKey", value: key.base64);
    await storage.write(key: "IV", value: iv.base64);
    await storage.write(key: prefs.getString("authId"), value: "true");
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(color: Color.fromRGBO(13, 13, 13, 1.0)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Spacer(),
            textWidget("Welcome", 1),
            textWidget("To", 2),
            textWidget("Food Inventory", 3),
            Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 30.0),
              child: siginbutton(3500),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: Center(
                  child: Text(
                "Created with ❤️ by Yash",
                style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.6)),
              )),
            )
          ],
        ),
      ),
    );
  }

  Widget textWidget(String text, int seconds) {
    return Padding(
      padding: EdgeInsets.only(left: 30.0),
      child: DelayedDisplay(
        delay: Duration(seconds: seconds),
        child: Text(
          "$text ",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 35.0,
            color: Color.fromRGBO(109, 97, 231, 1.0),
          ),
        ),
      ),
    );
  }

  Widget siginbutton(int millis) {
    return DelayedDisplay(
      delay: Duration(milliseconds: millis),
      child: SignInButton(
        padding: 8.0,
        buttonType: ButtonType.google,
        onPressed: () => googleSignin(),
      ),
    );
  }
}
