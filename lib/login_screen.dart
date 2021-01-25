import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:food_inventory/main.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:delayed_display/delayed_display.dart';
import 'package:sign_button/sign_button.dart';

const users = const {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};

class LoginScreen extends StatelessWidget {
  Duration get loginTime => Duration(milliseconds: 2250);

  Future<User> googleSignin() async {
    print('i cam ');
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
      final user = await FirebaseAuth.instance.signInWithCredential(credential);
      assert(user.user.email != null);
      assert(user.user.displayName != null);
      assert(!user.user.isAnonymous);
      assert(await user.user.getIdToken() != null);
      currentUser = await FirebaseAuth.instance.currentUser;
      assert(user.user.uid == currentUser.uid);
      Get.offAll(HomeScreen(), transition: Transition.cupertino);
      print(currentUser);
      print("User Name : ${currentUser.displayName}");
    } catch (e) {
      print(e);
      return currentUser;
    }
  }

  Future<void> signOutGoogle() async {
    await GoogleSignIn().signOut();

    print("User Signed Out");
  }

  Future<String> _authUser(LoginData data) async {
    print('Name: ${data.name}, Password: ${data.password}');
    await googleSignin();
    // return Future.delayed(loginTime).then((_) {
    //   if (!users.containsKey(data.name)) {
    //     return 'Username not exists';
    //   }
    //   if (users[data.name] != data.password) {
    //     return 'Password does not match';
    //   }
    //   return null;
    // });
  }

  Future<String> _recoverPassword(String name) {
    print('Name: $name');
    return Future.delayed(loginTime).then((_) {
      if (!users.containsKey(name)) {
        return 'Username not exists';
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
    FlutterStatusbarcolor.setStatusBarColor(Color.fromRGBO(13, 13, 13, 1.0));
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
        padding: const EdgeInsets.only(top: 20.0,left:30.0),
        child: siginbutton(3500),
      ),
      Spacer(),
      
      Padding(
        padding: const EdgeInsets.only(bottom:15.0),
        child: Center(child: Text("Created with ❤️ by Yash",style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.6)),)),
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
