import 'dart:async';
import 'dart:convert';
import 'dart:ui';
// import 'dart:html';
import 'package:bot_toast/bot_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:food_inventory/login_screen.dart';
import 'package:food_inventory/models/food_model.dart';
import 'package:food_inventory/services/databse_service.dart';
import 'package:food_inventory/services/encryption.dart';
import 'package:food_inventory/update_modal.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:intl/intl.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:search_page/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(MyApp());
}




class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  String auth;

  void initState(){
    super.initState();
    getPrefs();
  }

  getPrefs()async{
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString("authId");

    setState(() {
      auth = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      builder: BotToastInit(), //1. call BotToastInit
      navigatorObservers: [BotToastNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      home: auth== null ? LoginScreen():HomeScreen(),
    );
  }
}




class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController _outputController;
  String returnedBarc = "";
  final _key = GlobalKey<AnimatedListState>();
  ScrollController _controller = ScrollController();
   int highlightIndex = 0;
   Color currentColor = Color.fromRGBO(109, 97, 231, 1.0);
    ItemController c = Get.put(ItemController());
     Encryption encryption = Encryption();

  void initState() {
    super.initState();
    this._outputController = TextEditingController();
     FlutterStatusbarcolor.setStatusBarWhiteForeground(false);
    FlutterStatusbarcolor.setStatusBarColor(Colors.white);
  }




  // encryptData(String text) {
  //   final key = encrypt.Key.fromSecureRandom(32);
  //   final iv = encrypt.IV.fromLength(16);

  //   final encrypter = encrypt.Encrypter(encrypt.AES(key));

  //   final encrypted = encrypter.encrypt(text, iv: iv);
  //   final decrypted = encrypter.decrypt(encrypted, iv: iv);

  //   print(decrypted); // Lorem ipsum dolor sit amet, consectetur adipiscing elit
  //   print(encrypted
  //       .base16); // R4PxiU3h8YoIRqVowBXm36ZcCeNeZ4s1OvVBTfFlZRdmohQqOpPQqD1YecJeZMAop/hZ4OxqgC1WtwvX/hP9mw==
  // }

  Future _scan() async {
    await Permission.camera.request();
    String barcode = await scanner.scan();
    if (barcode == null) {
      Get.rawSnackbar(
          message: "No barcode scanned",
          duration: Duration(milliseconds: 1000),
          animationDuration: Duration(milliseconds: 300));
      print('nothing return.');
    } else {
      this._outputController.text = barcode;
      setState(() {
        returnedBarc = barcode;
      });
      await addToDb();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _scan(),
          child: Icon(Icons.camera_alt),
          backgroundColor: Color.fromRGBO(222, 110, 131, 1.0),
        ),
        body: bodyView());
  }

  Widget bodyView() {
    return SafeArea(
      top: true,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 20.0,
        ),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 15.0, top: 10.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi ,${FirebaseAuth.instance.currentUser.displayName.split(" ").first} ",
                        style: TextStyle(
                            fontSize: 24.0, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Manage your inventory here",
                        style: TextStyle(
                            fontSize: 15.0,
                            color: Color.fromRGBO(0, 0, 0, 0.6)),
                      )
                    ],
                  ),
                  InkWell(
                    onTap: () { 
                      
                      Get.defaultDialog(
                        middleText: "Are you sure ?",
                        title: "Logout",
                        radius: 10.0,
                        buttonColor: Color.fromRGBO(109, 97, 231, 1.0),
                        cancelTextColor: Colors.black,
                        confirmTextColor: Colors.white,
                        
                      onConfirm: ()async{
                        GoogleSignIn().signOut();
                      FirebaseAuth.instance.signOut();
                      final prefs = await SharedPreferences.getInstance();
                      prefs.clear();
                      Get.offAll(LoginScreen(), transition: Transition.cupertino);
                      },
                      onCancel: () => Navigator.pop(context)
                      
                      );
                      
                      },
                    child: Icon(
                      Icons.account_box_outlined,
                      size: 30.0,
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
           Expanded(child: listView())
          ],
        ),
      ),
    );
  }

  Widget listView() {
    return StreamBuilder(
        stream: DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
            .getAllItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromRGBO(222, 110, 131, 1.0))));
          }
          if (snapshot.hasData) {
            List<QueryDocumentSnapshot> items =
                snapshot.data as List<QueryDocumentSnapshot>;
            if (items.length == 0) {
              return noItems();
            } else {
              return AnimatedList(
                  controller: _controller,
                  key: _key,
                  padding: EdgeInsets.all(10.0),
                  itemBuilder: (context, int index, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: foodItem(items[index], index),
                    );
                  },
                  initialItemCount: items.length);
            }
          }

          return Container();
        });
  }

  void _goToElement(int index) {
    _controller.animateTo(
        (74.0 *
            index), // 100 is the height of container and index of 6th element is 5
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut);
  }

  changeItemColor(){
     Timer(Duration(seconds: 0),(){
          setState(() {
            currentColor = Colors.deepOrange;
          });
        });
        setState(() {
          currentColor = Color.fromRGBO(109, 97, 231, 1.0);
        });
  }

  getDecText(text){
    return Encryption.decryptText(encrypt.Encrypted.fromBase64(text));
  }

  addToDb() async {
    final ref =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
            .recordExists(returnedBarc);

    await DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
        .updateRecord(returnedBarc);
    Map<String, int> data =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
            .getDataOfItems(id: returnedBarc);
    if (!ref.exists) {
      int index = data["nofOfItems"];
      if (index == 1) {
        setState(() {
          _key.currentState.insertItem(index - 1);
        });
      } else {
        _key.currentState.insertItem(index - 1);
      }
    } else {
      _goToElement(data["indexOfItem"]);
      c.setIndex(data["indexOfItem"]);
      // setState(() {
      //   highlightIndex = data["indexOfItem"];
      // });
     // changeItemColor();
    }
  }

  deleteFromDB(QueryDocumentSnapshot food, String id, int index) async {
    _key.currentState.removeItem(
      index,
      (BuildContext context, Animation<double> animation) {
        return FadeTransition(
          opacity:
              CurvedAnimation(parent: animation, curve: Interval(0.5, 1.0)),
          child: SizeTransition(
            sizeFactor:
                CurvedAnimation(parent: animation, curve: Interval(0.0, 1.0)),
            axisAlignment: 0.0,
            child: foodItem(food, index),
          ),
        );
      },
      duration: Duration(milliseconds: 600),
    );
    await DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
        .deleteRecord(id);
    BotToast.showSimpleNotification(
        title: "${food.get("foodName")} deleted",
        align: Alignment.bottomCenter,
        backgroundColor: Color.fromRGBO(0, 0, 0, 0.7),
        titleStyle: TextStyle(color: Colors.white),
        closeIcon: Icon(
          Icons.close,
          color: Colors.white,
        ));
  }

  Widget noItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Nothing here :/",
          style: TextStyle(
            color: Color.fromRGBO(0, 0, 0, 0.4),
          ),
        ),
        SizedBox(
          height: 2.0,
        ),
        Text("Start adding items ",
            style: TextStyle(color: Color.fromRGBO(0, 0, 0, 0.4)))
      ],
    );
  }

  Widget foodItem(QueryDocumentSnapshot food, int index) {
  
    return InkWell(
      onLongPress: () => showUpdateModal(context, food),
      onDoubleTap: () => deleteFromDB(food, food.id, index),
      child: Container(
        padding: EdgeInsets.all(10.0),
        margin: EdgeInsets.all(3.0),
        decoration: BoxDecoration(
            color: index == highlightIndex ? currentColor:Color.fromRGBO(109, 97, 231, 1.0),
            borderRadius: BorderRadius.all(Radius.circular(5.0))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                food.get("foodName").toString().contains("Loading name..")
                    ? Shimmer.fromColors(
                        baseColor: Colors.grey[300],
                        highlightColor: Colors.grey[100],
                        child: Text(
                         
                          food
                              .get("foodName")
                              .toString()
                              .split(" ")
                              .take(5)
                              .join(" "),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                        ),
                      )
                    : Text(
                       getDecText(food
                            .get("foodName"))
                            .toString()
                            .split(" ")
                            .take(5)
                            .join(" "),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 16.0),
                      ),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: 'Qty: ', style: TextStyle(color: Colors.white)),
                    TextSpan(
                        text: food.get("qty").toString(),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ]),
                ),
                // Text('Qty: ${food.get("qty").toString()}',
                //     style: TextStyle(color: Colors.white)),
              ],
            ),
            SizedBox(
              height: 5.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getDecText(food.id),
                  style: TextStyle(
                      fontSize: 12.0,
                      color: Color.fromRGBO(255, 255, 255, 0.7)),
                ),
                Text(
                  "${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(food.get("date")))}",
                  style: TextStyle(
                      fontSize: 12.0,
                      color: Color.fromRGBO(255, 255, 255, 0.7)),
                )
              ],
            ),
            SizedBox(
              height: 10.0,
            )
          ],
        ),
      ),
    );
  }

//   showSearchPage()async{
//    List<Person> people = [
//     Person('Mike', 'Barron', 64),
//     Person('Todd', 'Black', 30),
//     Person('Ahmad', 'Edwards', 55),
//     Person('Anthony', 'Johnson', 67),
//     Person('Annette', 'Brooks', 39),
//   ];

//     // final items = await DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
//     //         .getAllItems().toList();
//     //         print(items);
//      showSearch(
//           context: context,
//           delegate: SearchPage<Person>(
//             items: people,
//             searchLabel: 'Search people',
//             suggestion: Center(
//               child: Text('Filter people by name, surname or age'),
//             ),
//             failure: Center(
//               child: Text('No person found :('),
//             ),
//             filter: (person) => [
//               person.name,
//               person.surname,
//               person.age.toString(),
//             ],
//             builder: (person) => ListTile(
//               title: Text(person.name),
//               subtitle: Text(person.surname),
//               trailing: Text('${person.age} yo'),
//             ),
//           ),
//         );

}

//   }
// }
// class Person {
//   final String name, surname;
//   final num age;

//   Person(this.name, this.surname, this.age);
// }
//Barcode scanning works - no image pickup - DOne
//Google login - Done
//Encryption - done
//fireabse firestore connect - done

//daat model and data service,repository - done

//New tasks
//edit quantity and name - form and api - done
//ftech names from API - done
//mention bought on ui - done
//highlighting when increasing qty

//new tasks
//add to db - scroll to index nut work with aniamted list -> done
// updating quanitty of existing item hightlight it
//encrypt data
//Google sign in and intro screen -> done
//user logout and clean code -> done
//deploy to ustsavized :)


class ItemController extends GetxController{
  RxInt highIndex = 0.obs;

  setIndex(int index){
    highIndex.value = index;
    update();
  }
}
