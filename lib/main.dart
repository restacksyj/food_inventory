import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:food_inventory/login_screen.dart';
import 'package:food_inventory/search_page.dart';
import 'package:food_inventory/services/database_service.dart';
import 'package:food_inventory/services/encryption.dart';
import 'package:food_inventory/update_modal.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:overlay_support/overlay_support.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:intl/intl.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/rendering.dart';

final Color pink = Color.fromRGBO(222, 110, 131, 1.0);
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

  void initState() {
    super.initState();
    getPrefs();
  }

  getPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString("authId");

    setState(() {
      auth = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(Color.fromRGBO(37, 37, 37, 1.0));

    return OverlaySupport(
      child: GetMaterialApp(
        theme: ThemeData(fontFamily: "Manrope"),
        debugShowCheckedModeBanner: false,
        home: auth == null ? LoginScreen() : HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _key = GlobalKey<AnimatedListState>();
  ScrollController _controller = ScrollController();
  Encryption encryption = Encryption();
  BehaviorSubject<int> scrolledIndex = BehaviorSubject<int>();
  BehaviorSubject<String> barcodeStream = BehaviorSubject<String>();

  void initState() {
    super.initState();
    //  FlutterStatusbarcolor.setStatusBarWhiteForeground(false);
    // FlutterStatusbarcolor.setStatusBarColor(Colors.black);
  }

  void dispose() {
    super.dispose();
    scrolledIndex.close();
    barcodeStream.close();
  }

  listState(QueryDocumentSnapshot food, int index) async {
    return await deleteFromDB(food, food.id, index);
  }

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
      barcodeStream.add(barcode);
      await addToDb();
      Future.delayed(Duration(seconds: 1));
      barcodeStream.add(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
        floatingActionButton: FloatingActionButton(
          tooltip: "Scan",
          child: Icon(Icons.qr_code_scanner),
          //label: Container(),
          //isExtended: false,
          onPressed: () => _scan(),
          backgroundColor: Color.fromRGBO(222, 110, 131, 1.0),
        ),
        body: bodyView());
  }

  // Widget sliverView(){
  //   return CustomScrollView(
  //     slivers: [
  //       SliverAppBar(
  //         expandedHeight: 100.0,

  //         floating: false,
  //         pinned: true,
  //         flexibleSpace: FlexibleSpaceBar(),
  //         title: Text("Inventory"),
  //       ),
  //       SliverFillRemaining(

  //         child:listView() ,
  //       )
  //     ],
  //   );
  // }

  Widget bodyView() {
    return SafeArea(
      top: true,
      child: Container(
        padding: const EdgeInsets.only(top: 10.0),
        color: Color.fromRGBO(37, 37, 37, 1.0),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 15.0, top: 10.0, right: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  appbarText(),
                  buttonBar(),
                ],
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            Expanded(
                child: OfflineBuilder(
              child: listView(),
              connectivityBuilder: (
                context,
                ConnectivityResult connectivity,
                Widget child,
              ) {
                final bool connected = connectivity != ConnectivityResult.none;
                return connected ? listView() : noInternet();
              },
            ))
          ],
        ),
      ),
    );
  }

  ButtonBar buttonBar() {
    return ButtonBar(
      mainAxisSize: MainAxisSize.min,
      alignment: MainAxisAlignment.spaceAround,
      buttonPadding: EdgeInsets.only(left: 0.0),
      children: [
        InkWell(
          radius: 30.0,
          customBorder: CircleBorder(),
          onTap: () => onLogout(),
          child: Icon(
            Icons.logout,
            size: 30.0,
            color: Colors.white,
          ),
        ),
        SizedBox(
          width: 15.0,
        ),
        InkWell(
            radius: 30.0,
            customBorder: CircleBorder(),
            onTap: () => Get.to(SearchPage(),
                transition: Transition.cupertino, arguments: listState),
            child: Icon(
              Icons.search,
              size: 30.0,
              color: Colors.white,
            ))
      ],
    );
  }

  Column appbarText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hi ,${FirebaseAuth.instance.currentUser.displayName.split(" ").first} ",
          style: TextStyle(
              fontSize: 24.0, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        Text(
          "Manage your inventory here",
          style: TextStyle(
              fontSize: 15.0,
              color: Color.fromRGBO(255, 255, 255, 0.6),
              fontWeight: FontWeight.w600),
        ),
        Padding(padding: EdgeInsets.only(bottom: 10.0)),
      ],
    );
  }

  onLogout() {
    return Get.defaultDialog(
        middleText: "Are you sure ?",
        title: "Logout",
        radius: 10.0,
        buttonColor: Color.fromRGBO(109, 97, 231, 1.0),
        cancelTextColor: Colors.black,
        confirmTextColor: Colors.white,
        onConfirm: () async {
          GoogleSignIn().signOut();
          FirebaseAuth.instance.signOut();
          final prefs = await SharedPreferences.getInstance();
          prefs.clear();
          Get.offAll(LoginScreen(), transition: Transition.cupertino);
        },
        onCancel: () => Navigator.pop(context));
  }

  Widget listView() {
    return StreamBuilder(
        stream: DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
            .getAllItems(),
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.waiting) {
          //   return Center(
          //       child: CircularProgressIndicator(
          //           valueColor: AlwaysStoppedAnimation<Color>(
          //               Color.fromRGBO(222, 110, 131, 1.0))));
          // }
          if (snapshot.hasData) {
            List<QueryDocumentSnapshot> items =
                snapshot.data as List<QueryDocumentSnapshot>;
            if (items.length == 0) {
              return noItems();
            } else {
              return Container(
                color: Color.fromRGBO(13, 13, 13, 1.0),
                child: ScrollConfiguration(
                  behavior: ScrollBehavior(),
                  child: GlowingOverscrollIndicator(
                    color: blue,
                    axisDirection: AxisDirection.down,
                    child: Scrollbar(
                      child: AnimatedList(
                          controller: _controller,
                          key: _key,
                          padding: EdgeInsets.all(10.0),
                          itemBuilder: (context, int index, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: foodItem(items[index], index),
                            );
                          },
                          initialItemCount: items.length),
                    ),
                  ),
                ),
              );
            }
          }

          return Container();
        });
  }

  void _goToElement(int index) {
    scrolledIndex.add(index);

    _controller.animateTo(
        (100.0 *
            index), // 100 is the height of container and index of 6th element is 5
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: 1500), () {
      scrolledIndex.add(null);
    });
  }

  getDecText(text) {
    return Encryption.decryptText(encrypt.Encrypted.fromBase16(text));
  }

  addToDb() async {
    final ref =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
            .recordExists(barcodeStream.value);

    await DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
        .updateRecord(barcodeStream.value);
    Map<String, int> data =
        await DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
            .getDataOfItems(id: barcodeStream.value);
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
    toast("${getDecText(food.get("foodName"))} deleted");
  }

  Widget noInternet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "No internet connection :/",
          style: TextStyle(
            color: Color.fromRGBO(0, 0, 0, 0.4),
          ),
        ),
        SizedBox(
          height: 2.0,
        ),
        Text("You're currently offline ",
            style: TextStyle(color: Color.fromRGBO(0, 0, 0, 0.4)))
      ],
    );
  }

  Widget noItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Nothing here :/",
          style: TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.4),
          ),
        ),
        SizedBox(
          height: 2.0,
        ),
        Text("Start adding items ",
            style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.4)))
      ],
    );
  }

  Widget imageWidget(url) {
    return url == null || getDecText(url) == ""
        ? clipRRect(Center(
            child: Icon(
              Icons.close,
              size: 35.0,
            ),
          ))
        : clipRRect(Image.network(
            getDecText(url),
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                  child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(pink),
              ));
            },
            errorBuilder: (context, _, __) {
              return clipRRect(Center(
                child: Icon(
                  Icons.close,
                  size: 35.0,
                ),
              ));
            },
            width: 75.0,
            height: 75.0,
            fit: BoxFit.fill,
          ));
    //  CachedNetworkImage(
  }

  ClipRRect clipRRect(Widget widget) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5.0),
      child: Container(
        color: Colors.grey,
        width: 75.0,
        height: 75.0,
        child: widget,
      ),
    );
  }

  Widget foodItem(QueryDocumentSnapshot food, int index) {
    
    return StreamBuilder<Object>(
        stream: scrolledIndex,
        builder: (context, snapshotTwo) {
          return InkWell(
            onTap: () => showUpdateModal(context, food),
            onDoubleTap: () => deleteFromDB(food, food.id, index),
            child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(5.0)),
                          child: Container(
                padding: EdgeInsets.all(8.0),
                // margin: EdgeInsets.only(bottom: 3.0),
                decoration: BoxDecoration(
                    // border: Border.all(color:Colors.green,width: 2.0),
                    border: Border(
                        bottom:
                            BorderSide(color: Color.fromRGBO(13, 13, 13, 1.0)),
                        top: BorderSide(color: Color.fromRGBO(13, 13, 13, 1.0)),
                        right: BorderSide(color: Color.fromRGBO(13, 13, 13, 1.0)),
                        left: BorderSide(
                            color: food.get("qty") == 0
                                ? Colors.red[400]
                                : Color.fromRGBO(13, 13, 13, 1.0),width: 5.0
                                )),
                    color: index == scrolledIndex.value
                        ? Colors.orange
                        : Color.fromRGBO(13, 13, 13, 1.0),
                    // borderRadius: BorderRadius.all(Radius.circular(5.0))
                    ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        imageWidget(food.get("imageUrl")),
                        SizedBox(width:15.0),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              food
                                      .get("foodName")
                                      .toString()
                                      .contains("Loading name..")
                                  ? SizedBox(
                                      width: 200.0,
                                      child: Shimmer.fromColors(
                                        baseColor: Colors.grey[300],
                                        highlightColor: Colors.grey[100],
                                        child: Text(
                                          food.get("foodName"),
                                          // .toString()
                                          // .split(" ")
                                          // .take(5)
                                          // .join(" "),
                                          overflow: TextOverflow.ellipsis,

                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.0),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: MediaQuery.of(context).size.width/1.5,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                          getDecText(food.get("foodName")),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16.0),
                                        ),
                                      ),
                                    ),
                              SizedBox(
                                height: 2.0,
                              ),
                              RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                      text: 'Qty: ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  TextSpan(
                                      text: food.get("qty").toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      )),
                                ]),
                              ),
                              SizedBox(
                                height: 4.0,
                              ),
                              Text(
                                getDecText(food.id),
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromRGBO(255, 255, 255, 0.7)),
                              ),
                              SizedBox(
                                height: 2.0,
                              ),
                              Text(
                                "${DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(food.get("date")))}",
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w500,
                                    color: Color.fromRGBO(255, 255, 255, 0.7)),
                              )
                            ],
                          ),
                        ),
                       //SizedBox(width: 30.0,)
                      ],
                    ),
                    SizedBox(
                      height: 5.0,
                    ),

                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [

                    //   ],
                    // ),
                    // SizedBox(
                    //   height: 10.0,
                    // )
                  ],
                ),
              ),
            ),
          );
        });
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
//highlighting when increasing qty -> done

//new tasks
//add to db - scroll to index nut work with aniamted list -> done
// updating quanitty of existing item by hightlighting it -> done
//encrypt data -> done
//fix statusbarcolor -> done
//Google sign in and intro screen -> done
//user logout and clean code -> done
//deploy to ustsavized :)

//last tasks
//getImage and chnage layout of foodTile -> done (partially)
//add search
//done , no more this is it
