import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_inventory/models/food_model.dart';
import 'package:food_inventory/models/user_model.dart';
import 'package:get/get.dart';

class DatabaseService {
  final String uid;
  final GetFood foodGetter = GetFood();
  DatabaseService({this.uid});
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  Stream getAllItems() {
    return usersCollection
        .doc(uid)
        .collection("foods")
        .orderBy("date", descending: false)
        .snapshots()
        .map((event) => event.docs.toList());
  }

  Future<int> getNumberOfItems() async {
    final len = await usersCollection.doc(uid).collection("foods").get();
    return len.docs.length;
  }

  Future<void> createRecord(String name) async {
    var date = DateTime.now().millisecondsSinceEpoch;
    try {
      await usersCollection
          .doc(uid)
          .collection("foods")
          .doc(name)
          .set(FoodModel(foodName: "Loading name..", date: date, qty: 1).toJson());
      final foodname = await foodGetter.getfoodName(name);
      await usersCollection
            .doc(uid)
            .collection("foods")
            .doc(name)
            .update({"foodName": foodname});
    } on SocketException {
      Get.showSnackbar(GetBar(
        title: "Failed",
        message: "Coudln't create record. Please try again",
        duration: Duration(seconds: 3),
      ));
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  updateRecord(String barcode) async {
    try {
      final docref =
          await usersCollection.doc(uid).collection("foods").doc(barcode).get();
      if (docref.exists) {
      BotToast.showSimpleNotification(
            title: "Item exists. Updating quantity",
            align: Alignment.bottomCenter,
            backgroundColor: Color.fromRGBO(0, 0, 0, 0.7),
            titleStyle: TextStyle(color: Colors.white),
            closeIcon: Icon(
              Icons.close,
              color: Colors.white,
            ));
        return await usersCollection
            .doc(uid)
            .collection("foods")
            .doc(barcode)
            .update({"qty": docref.get("qty") + 1});
      } else {
        createRecord(barcode);
        BotToast.showSimpleNotification(
            title: "Added to inventory",
            align: Alignment.bottomCenter,
            backgroundColor: Color.fromRGBO(0, 0, 0, 0.7),
            titleStyle: TextStyle(color: Colors.white),
            closeIcon: Icon(
              Icons.close,
              color: Colors.white,
            ));
      }
    } on SocketException {
      Get.showSnackbar(GetBar(
        title: "Failed",
        message: "Coudln't create record. Please try again",
        duration: Duration(seconds: 3),
      ));
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  recordExists(String barcode)async{
    try{
      final docref =
          await usersCollection.doc(uid).collection("foods").doc(barcode).get();
          return docref;
    }on SocketException {
      Get.showSnackbar(GetBar(
        title: "Failed",
        message: "Something went wrong. Please try again",
        duration: Duration(seconds: 3),
      ));
    }catch(e){
      print(e);
      rethrow;
    }
  }

  deleteRecord(String name) async {
    await usersCollection.doc(uid).collection("foods").doc(name).delete();
  }

  updateFoodItem({String foodName, int qty, String barcode}) async {
    try {
      return await usersCollection
          .doc(uid)
          .collection("foods")
          .doc(barcode)
          .update({"foodName": foodName, "qty": qty});
    } on SocketException {
      Get.showSnackbar(GetBar(
        title: "Failed",
        message: "Coudln't create record. Please try again",
        duration: Duration(seconds: 3),
      ));
    } catch (e) {
      print(e);
      rethrow;
    }

  }
}

class GetFood extends GetConnect{
  Future<String> getfoodName(String barcode)async{
    final res =await get("https://world.openfoodfacts.org/api/v0/product/$barcode.json");
    final data = res.body;
    if(data["status"]==1){
    return data["product"]["product_name"].toString()=="null" ?"No name":data["product"]["product_name"].toString();
    }else{
      print("Product not found");
      return "No name";
    }
  }
}