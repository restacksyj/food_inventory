import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_inventory/services/database_service.dart';
import 'package:food_inventory/services/encryption.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:food_inventory/update_modal.dart';
import 'package:get/get.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shimmer/shimmer.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool _isSearching = true;
  String filter = "";
  TextEditingController _searchQuery = TextEditingController();

  void updateSearchQuery(String newQuery) {
    setState(() {
      filter = newQuery;
    });
  }

  Widget _buildSearchField() {
    return new TextField(
      controller: _searchQuery,
      autofocus: true,
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      cursorColor: Colors.white,
      decoration: const InputDecoration(
        hintText: 'Search list...',
        hintStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        border: InputBorder.none,
      ),
      onChanged: updateSearchQuery,
    );
  }

  void _clearSearchQuery() {
    setState(() {
      _searchQuery.clear();
      updateSearchQuery("");
    });
  }

  void _startSearch() {
    ModalRoute.of(context)
        .addLocalHistoryEntry(new LocalHistoryEntry(onRemove: _stopSearching));

    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearching() {
    _clearSearchQuery();
    setState(() {
      _isSearching = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchQuery = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _searchQuery.dispose();
  }

  getDecText(text) {
    return Encryption.decryptText(encrypt.Encrypted.fromBase16(text));
  }

  deleteFromDB(QueryDocumentSnapshot food) async {
    await DatabaseService(uid: FirebaseAuth.instance.currentUser.uid)
        .deleteRecord(food.id);
    toast("${getDecText(food.get("foodName"))} deleted");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbarSearching(),
      body: Container(
        color: Color.fromRGBO(13, 13, 13, 1.0),
        child: listView()),
    );
  }

  Widget appbarSearching() {
    return AppBar(
        title: _isSearching ? _buildSearchField() : Text("Food list"),
        elevation: 0.0,
        backgroundColor: Color.fromRGBO(37, 37, 37, 1.0),
        centerTitle: true,
        leading: _isSearching
            ? InkWell(
                child: Icon(Icons.arrow_back_ios),
                onTap: () => Navigator.of(context).pop(),
              )
            : null,
        actions: _isSearching && _searchQuery.text.length > 0
            ? <Widget>[
                new IconButton(
                  icon: Icon(
                    Icons.clear,
                  ),
                  onPressed: () {
                    if (_searchQuery == null || _searchQuery.text.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }
                    _clearSearchQuery();
                  },
                ),
              ]
            : [
                Container()
                // Padding(
                //   padding: const EdgeInsets.all(16.0),
                //   child: InkWell(
                //     child: Icon(Icons.search),
                //     onTap: _startSearch,
                //   ),
                // )
              ]);
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
              return ScrollConfiguration(
                behavior: ScrollBehavior(),
                child: GlowingOverscrollIndicator(
                  color: blue,
                  axisDirection: AxisDirection.down,
                  child: Scrollbar(
                    child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          if (_isSearching) {
                            return filter.isEmpty
                                ? foodItemTile(items[index], index)
                                : (getDecText(items[index].get("foodName")))
                                        .toString()
                                        .toLowerCase()
                                        .contains(filter.toLowerCase())
                                    ? foodItemTile(items[index], index)
                                    : Container();
                          }
                          return foodItemTile(items[index], index);
                        }),
                  ),
                ),
              );
            }
          }
          return Container();
        });
  }

  Widget foodItemTile(QueryDocumentSnapshot food, int index) {
    return Column(
      children: [
        foodItemTileLayout(food, index),
        // SizedBox(height: 10.0,)
      ],
    );
  }

  Widget foodItemTileLayout(QueryDocumentSnapshot food, int index) {
    String foodName = getDecText(food.get("foodName"));
    return InkWell(
      onTap: () {
        showUpdateModal(context, food);
        // Navigator.of(context).pop();
        // FocusManager.instance.primaryFocus.unfocus();
      },
      onDoubleTap: () {
        deleteFromDB(food);
        var data = Get.arguments;
        data(food, index);
      },
      child: Container(
        decoration: BoxDecoration(
            color: index.isOdd ? Colors.grey[850]: Color.fromRGBO(13, 13, 13, 1.0)),
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                food.get("foodName").toString().contains("Loading name..")
                    ? SizedBox(
                        width: 200.0,
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300],
                          highlightColor: Colors.grey[100],
                          child: Text(
                            food.get("foodName"),
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: Colors.white, fontSize: 16.0),
                          ),
                        ),
                      )
                    : SizedBox(
                        width: 230.0,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(getDecText(food.get("foodName")),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: "Manrope",
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        )),
                RichText(
                  text: TextSpan(
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                            text: "Qty: ${food.get("qty").toString()}",
                            style: TextStyle(
                                color: food.get("qty") == 0
                                    ? Colors.red[400]
                                    : Colors.white,
                                fontFamily: "Manrope",
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
                // Text("Qty: ${food.get("qty").toString()}",style: TextStyle(fontFamily: "Manrope",fontWeight: FontWeight.w600) ,)
              ],
            ),
            Visibility(
              child: Text(
                "* Needs to be stocked",
                style: TextStyle(fontSize: 10.0, fontStyle: FontStyle.italic,color: Colors.white60),
              ),
              visible: food.get("qty") == 0,
            )
          ],
        ),
      ),
    );
  }

  Widget noItems() {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
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
      ),
    );
  }
}
