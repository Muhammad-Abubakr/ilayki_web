import 'dart:convert';

class Product {
  final String pid;
  final String ownerUid;
  final String name;
  final double price;
  final int quantity;
  final String productImage;

  Product({
    required this.pid,
    required this.ownerUid,
    required this.name,
    required this.price,
    required this.quantity,
    required this.productImage,
  });

  Product copyWith({
    String? pid,
    String? ownerUid,
    String? name,
    double? price,
    int? quantity,
    String? productImage,
  }) {
    return Product(
      pid: pid ?? this.pid,
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      productImage: productImage ?? this.productImage,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pid': pid,
      'ownerUid': ownerUid,
      'name': name,
      'price': price,
      'quantity': quantity,
      'productImage': productImage,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      pid: map['pid'] as String,
      ownerUid: map['ownerUid'] as String,
      name: map['name'] as String,
      price: map['price'] as double,
      quantity: map['quantity'] as int,
      productImage: map['productImage'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Product.fromJson(String source) =>
      Product.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Product(pid: $pid, ownerUid: $ownerUid, name: $name, price: $price, quantity: $quantity, productImage: $productImage)';
  }

  @override
  bool operator ==(covariant Product other) {
    if (identical(this, other)) return true;

    return other.pid == pid &&
        other.ownerUid == ownerUid &&
        other.name == name &&
        other.price == price &&
        other.productImage == productImage &&
        other.quantity == quantity;
  }

  @override
  int get hashCode {
    return pid.hashCode ^
        ownerUid.hashCode ^
        name.hashCode ^
        price.hashCode ^
        quantity.hashCode;
  }
}
