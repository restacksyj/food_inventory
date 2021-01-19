
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_inventory/main.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_core/firebase_core.dart';

const users = const {
  'dribbble@gmail.com': '12345',
  'hunter@gmail.com': 'hunter',
};

class LoginScreen extends StatelessWidget {
  Duration get loginTime => Duration(milliseconds: 2250);

 Future <User> googleSignin() async {  
   print('i cam ');
    User currentUser;  
    try {  
        final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();  
        print(googleUser.toString());
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;  
        final AuthCredential credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken, );  
        final  user = await FirebaseAuth.instance.signInWithCredential(credential);  
        assert(user.user.email != null);  
        assert(user.user.displayName != null);  
        assert(!user.user.isAnonymous);  
        assert(await user.user.getIdToken() != null);  
        currentUser = await FirebaseAuth.instance.currentUser;
        assert(user.user.uid == currentUser.uid);  
       Get.offAll(HomeScreen(),transition: Transition.cupertino);
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

  Future<String> _authUser(LoginData data)async {
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
    return Scaffold(
          body: Container(
        child: Center(
          child: RaisedButton(onPressed:()=>  googleSignin(),child: Text('Sign in'),),
        ),
      ),
    );
}
}