import 'package:cloud_firestore/cloud_firestore.dart';

class FoodModel{
  String foodName;
  int date;
  num qty;
  FoodModel({this.foodName,this.date,this.qty});


   Map<String, dynamic> toJson() => 
  {
    'date': this.date,
    'qty': this.qty,
    'foodName': this.foodName,
  };


}


