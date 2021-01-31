import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_inventory/models/food_model.dart';
import 'package:food_inventory/services/database_service.dart';
import 'package:food_inventory/services/encryption.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:overlay_support/overlay_support.dart';

final GlobalKey<FormState> _formKeyTwo = GlobalKey<FormState>();
final TextEditingController _updateFoodName = TextEditingController();
final TextEditingController _updateFoodQty = TextEditingController();
final Color blue = Color.fromRGBO(109, 97, 231, 1.0);
final Color pink = Color.fromRGBO(222, 110, 131, 1.0);

getDecText(text) {
  return Encryption.decryptText(encrypt.Encrypted.fromBase64(text));
}

showUpdateModal(BuildContext context, QueryDocumentSnapshot food) {
  _updateFoodName.text = Encryption.decryptText(
      encrypt.Encrypted.fromBase64(food.get("foodName")));
  _updateFoodQty.text = food.get("qty").toString();
  return showMaterialModalBottomSheet(
    expand: false,
    enableDrag: true,
    backgroundColor: Color.fromRGBO(13, 13, 13, 1.0),

    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0))),
    context: context,
    builder: (context) => WillPopScope(
      child: modalBody(context, food),
      onWillPop: () async => true,
    ),
  );
}

Widget modalBody(BuildContext context, QueryDocumentSnapshot food) {
  return Container(
    // color: Color.fromRGBO(13, 13, 13, 1.0),
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    height: MediaQuery.of(context).size.height / 1.2,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 100.0),
          child: Text(
            "Update Item",
            style: TextStyle(
                fontSize: 20.0, color: blue, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 10.0,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
          child: Form(
            key: _formKeyTwo,
            child: Row(
              children: [
                Flexible(
                  child: SizedBox(
                    height: 80.0,
                    child: TextFormField(
                      controller: _updateFoodName,
                      onFieldSubmitted: (value) {
                        if (value.isNotEmpty) {
                          formValid(context, food);

                          updateSuccessfully();
                        } else {
                          toast('Value cannot be empty');
                        }
                      },
                      validator: (String value) {
                        if (value.length == 0 || value.isEmpty) {
                          return "Enter valid name";
                        }
                        return null;
                      },
                      cursorColor: blue,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          isDense: true,
                          labelText: "Food Name",
                          labelStyle: TextStyle(color: blue),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          filled: true,
                          hintText: "Food item",
                          hintStyle: TextStyle(color: Colors.white),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: blue,
                            ),
                          ),
                          enabledBorder:  OutlineInputBorder(
                            borderRadius:  BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: blue),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 16.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: blue,
                            ),
                          )),
                      autofocus: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Flexible(
                  child: SizedBox(
                    height: 80.0,
                    child: TextFormField(
                      controller: _updateFoodQty,
                      cursorColor: blue,
                      onFieldSubmitted: (value) {
                        // print("onfield");
                        if (value.isNotEmpty) {
                          formValid(context, food);
                          // MovieService().updateData(movie.id,value);
                          // Navigator.of(context).pop();
                          updateSuccessfully();
                        } else {
                          // showToast("Value cannot be empty");
                          toast('Value cannot be empty');
                        }
                      },
                      // initialValue: food.get("qty").toString(),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      validator: (String value) {
                        if (value.isEmpty || num.parse(value) < 0) {
                          return "Enter valid qty";
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        enabledBorder:  OutlineInputBorder(
                            borderRadius:  BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: blue),
                          ),
                          isDense: true,
                          labelText: "Qty",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelStyle: TextStyle(color: blue),
                          filled: true,
                          hintText: "Quantity",
                          hintStyle: TextStyle(color: Colors.black),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: blue,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 16.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(
                              color: blue,
                            ),
                          )),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
        SizedBox(
          height: 20.0,
        ),
        button(food, context)
      ],
    ),
  );
}

Widget button(QueryDocumentSnapshot food, context) {
  return RaisedButton(
    elevation: 0.0,
    color: blue,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
    onPressed: () => formValid(context, food),
    child: Text(
      "Done",
      style: TextStyle(color: Colors.white),
    ),
    padding: EdgeInsets.all(16.0),
  );
}

updateSuccessfully() {
  return toast("Updated Successfully");
}

formValid(context, food) {
  if (_formKeyTwo.currentState.validate()) {
    _formKeyTwo.currentState.save();
    DatabaseService(uid: FirebaseAuth.instance.currentUser.uid).updateFoodItem(
        foodName: _updateFoodName.text,
        barcode: food.id,
        qty: int.parse(_updateFoodQty.text));
    Navigator.of(context).pop();
    updateSuccessfully();
  } else {
    toast('Value cannot be empty');
  }
}
