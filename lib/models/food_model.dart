
class FoodModel{
  String foodName;
  int date;
  num qty;
  String imageUrl;
  FoodModel({this.foodName,this.date,this.qty,this.imageUrl});


   Map<String, dynamic> toJson() => 
  {
    'date': this.date,
    'qty': this.qty,
    'foodName': this.foodName,
    'imageUrl':this.imageUrl
  };


}


