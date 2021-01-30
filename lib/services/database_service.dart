import 'dart:io';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_inventory/models/food_model.dart';
import 'package:food_inventory/services/encryption.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:get/get.dart';
import 'package:overlay_support/overlay_support.dart';

class DatabaseService {
  final String uid;
  final GetFood foodGetter = GetFood();
  DatabaseService({this.uid});
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  final Encryption encryption = Encryption();

  encBarc(String barcode) {
    final encStr = Encryption.encryptText(barcode).base64;
    return encStr.replaceAll("/", "*");
  }

  Stream getAllItems() {
    return usersCollection
        .doc(uid)
        .collection("foods")
        .orderBy("date", descending: false)
        .snapshots()
        .map((event) => event.docs.toList());
  }

  Future<Map<String, int>> getDataOfItems({String id}) async {
    final Map<String, int> data = Map<String, int>();
    final res = await usersCollection
        .doc(uid)
        .collection("foods")
        .orderBy("date", descending: false)
        .get();
    data["nofOfItems"] = res.docs.length;
    data["indexOfItem"] =
        res.docs.indexWhere((element) => element.id == encBarc(id));
    print(data["indexOfItem"]);
    return data;
  }

  Future<int> getIndexOfItem(String id) async {
    final len = await usersCollection
        .doc(uid)
        .collection("foods")
        .orderBy("date", descending: false)
        .get();
    return len.docs.indexWhere((element) => element.id == id);
  }

  Future<void> createRecord(String barcode) async {
    var date = DateTime.now().millisecondsSinceEpoch;
    var encUrl = "";

    try {
      await usersCollection
          .doc(uid)
          .collection("foods")
          .doc(encBarc(barcode))
          .set(FoodModel(
                  foodName: "Loading name..", date: date, qty: 1, imageUrl: "")
              .toJson());
      final foodName = await foodGetter.getfoodName(barcode);
      final enc = Encryption.encryptText(foodName).base64;
      final foodImgUrl = await foodGetter.getfoodImg(barcode);
      if (foodImgUrl != null) {
        encUrl = Encryption.encryptText(foodImgUrl).base64;
      } else {
        encUrl = null;
      }
      await usersCollection
          .doc(uid)
          .collection("foods")
          .doc(encBarc(barcode))
          .update({"foodName": enc, "imageUrl": encUrl});
    } on SocketException {
      Get.showSnackbar(GetBar(
        title: "Failed",
        message: "Coudln't create record. Please try again",
        duration: Duration(seconds: 3),
      ));
    } on Exception {
      toast( "Some error occured");
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  updateRecord(String barcode) async {
    try {
      final docref = await usersCollection
          .doc(uid)
          .collection("foods")
          .doc(encBarc(barcode))
          .get();
      if (docref.exists) {
        toast("Item exists. Updating quantity");
      
        return await usersCollection
            .doc(uid)
            .collection("foods")
            .doc(encBarc(barcode))
            .update({"qty": docref.get("qty") + 1});
      } else {
        createRecord(barcode);
        toast("Added to inventory");
        
      }
    } on SocketException {
      Get.showSnackbar(GetBar(
        title: "Failed",
        message: "Coudln't create record. Please try again",
        duration: Duration(seconds: 3),
      ));
    } on Exception {
      toast( "Some error occured");
    } catch (e) {
      toast( "Some error occured");
      print(e);
      rethrow;
    }
  }

  recordExists(String barcode) async {
    try {
      final docref = await usersCollection
          .doc(uid)
          .collection("foods")
          .doc(encBarc(barcode))
          .get();
      return docref;
    } on SocketException {
      Get.showSnackbar(GetBar(
        title: "Failed",
        message: "Something went wrong. Please try again",
        duration: Duration(seconds: 3),
      ));
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  deleteRecord(String name) async {
    await usersCollection.doc(uid).collection("foods").doc(name).delete();
    getAllItems();
  }

  updateFoodItem({String foodName, int qty, String barcode}) async {
    try {
      final  encFoodName =
          Encryption.encryptText(foodName).base64;
      return await usersCollection
          .doc(uid)
          .collection("foods")
          .doc(barcode)
          .update({"foodName": encFoodName, "qty": qty});
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

class GetFood extends GetConnect {
  Future<String> getfoodName(String barcode) async {
    final res = await get(
        "https://world.openfoodfacts.org/api/v0/product/$barcode.json");
    final data = res.body;
    if (data["status"] == 1) {
      return data["product"]["product_name"].toString() == "null" ||
              data["product"]["product_name"].toString().isEmpty
          ? "No name"
          : data["product"]["product_name"].toString();
    } else {
      print("Product not found");
      return "No name";
    }
  }

  Future<String> getfoodImg(String barcode) async {
    final res = await get(
        "https://world.openfoodfacts.org/api/v0/product/$barcode.json");
    final data = res.body;
    if (data["status"] == 1) {
      print(data["product"]["image_small_url"].toString());
      if (data["product"]["image_small_url"] != null) {
        return data["product"]["image_small_url"].toString() == "null" ||
                data["product"]["image_small_url"].toString().isEmpty
            ? null
            : data["product"]["image_small_url"].toString();
      }else{
        return null;
      }
    } else {
      return null;
    }
  }
}


class GetData extends GetxController{

  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  RxList streamList = [].obs;

  Stream getAllItems() {
    return usersCollection
        .doc(FirebaseAuth.instance.currentUser.uid)
        .collection("foods")
        .orderBy("date", descending: false)
        .snapshots()
        .map((event) => streamList.add(event.docs.toList()) );
  }

}