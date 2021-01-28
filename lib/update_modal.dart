import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_inventory/models/food_model.dart';
import 'package:food_inventory/services/databse_service.dart';
import 'package:food_inventory/services/encryption.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

final GlobalKey<FormState> _formKeyTwo = GlobalKey<FormState>();
final TextEditingController _updateFoodName = TextEditingController();
final TextEditingController _updateFoodQty = TextEditingController();
final Color blue = Color.fromRGBO(109, 97, 231, 1.0);
final Color pink = Color.fromRGBO(222, 110, 131, 1.0);

getDecText(text){
    return Encryption.decryptText(encrypt.Encrypted.fromBase64(text));
  }

showUpdateModal(BuildContext context, QueryDocumentSnapshot food) {
  _updateFoodName.text = Encryption.decryptText(
      encrypt.Encrypted.fromBase64(food.get("foodName")));
  _updateFoodQty.text = food.get("qty").toString();
  return showMaterialModalBottomSheet(
    // expand: true,
    expand: false,

    enableDrag: true,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0), topRight: Radius.circular(25.0))),
    context: context,

    builder: (context) => WillPopScope(
      child: modalBody(context, food),
      onWillPop: () async => true,
    ),
  );
}

Widget modalBody(BuildContext context, QueryDocumentSnapshot food) {
  return Container(
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
                      // onEditingComplete: () {
                      //   print('Done');
                      //   if (_formKeyTwo.currentState.validate()) {
                      //     _formKeyTwo.currentState.save();
                      //   }
                      // },
                      onFieldSubmitted: (value) {
                        // print("onfield");
                        if (value.isNotEmpty) {
                          // MovieService().updateData(movie.id,value);
                          formValid(context, food);
                          // Navigator.of(context).pop();
                          BotToast.showSimpleNotification(
                              align: Alignment.bottomCenter,
                              title: "Updated Successfully",
                              backgroundColor: Color.fromRGBO(0, 0, 0, 0.7),
                              titleStyle: TextStyle(color: Colors.white),
                              closeIcon: Icon(
                                Icons.close,
                                color: Colors.white,
                              ));
                        } else {
                          // showToast("Value cannot be empty");
                          BotToast.showText(text: 'Value cannot be empty');
                        }
                      },
                      validator: (String value) {
                        if (value.length == 0 || value.isEmpty) {
                          return "Enter valid name";
                        }
                        return null;
                      },

                      cursorColor: blue,

                      //style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                          // fillColor: green,
                          isDense: true,
                          labelText: "Food Name",
                          labelStyle: TextStyle(color: blue),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          filled: true,
                          hintText: "Food item",
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
                          BotToast.showSimpleNotification(
                              align: Alignment.bottomCenter,
                              title: "Updated Successfully",
                              backgroundColor: Color.fromRGBO(0, 0, 0, 0.7),
                              titleStyle: TextStyle(color: Colors.white),
                              closeIcon: Icon(
                                Icons.close,
                                color: Colors.white,
                              ));
                        } else {
                          // showToast("Value cannot be empty");
                          BotToast.showText(text: 'Value cannot be empty');
                        }
                      },
                      // initialValue: food.get("qty").toString(),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      validator: (String value) {
                        if (num.parse(value) == 0 ||
                            value.isEmpty ||
                            num.parse(value) < 0) {
                          return "Enter valid qty";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
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
        // buttons(context,food.id)
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

formValid(context, food) {
  if (_formKeyTwo.currentState.validate()) {
    _formKeyTwo.currentState.save();
    DatabaseService(uid: FirebaseAuth.instance.currentUser.uid).updateFoodItem(
        foodName: _updateFoodName.text,
        barcode: food.id,
        qty: int.parse(_updateFoodQty.text));
    Navigator.of(context).pop();
    BotToast.showSimpleNotification(
        align: Alignment.bottomCenter,
        title: "Updated Successfully",
        backgroundColor: Color.fromRGBO(0, 0, 0, 0.7),
        titleStyle: TextStyle(color: Colors.white),
        closeIcon: Icon(
          Icons.close,
          color: Colors.white,
        ));
  } else {
    BotToast.showText(text: 'Value cannot be empty');
  }
}

// Widget buttons(context,String id){
//   return Row(
//     mainAxisAlignment: MainAxisAlignment.center,
//     children: [
//       RaisedButton(
//           child: Text(
//             'CANCEL',
//             style: TextStyle(color: blue),
//           ),
//           onPressed: () {
//             Navigator.pop(context);
//           }),
//           SizedBox(width: 10.0,),
//       RaisedButton(
//           child: Text(
//             'UPDATE',
//             style: TextStyle(color: blue),
//           ),
//           onPressed: () {
//             if (_formKeyTwo.currentState.validate()) {
//               _formKeyTwo.currentState.save();
//               //createRecord();
//               // print(_updatemMovieName.text);
//               //  MovieService().updateData(id,_updatemMovieName.text);
//               // showToast("Movie Updated successfully",
//               //     animation: StyledToastAnimation.slideFromBottomFade,
//               //     context: context,
//               //     backgroundColor: Colors.black);

//               // Navigator.pop(context);
//               //  _updatemMovieName.clear();
//               // _updatemMovieName.clear();
//             }
//           })
//     ],
//   );
// }
