import 'package:json_annotation/json_annotation.dart';

part 'car.g.dart';

@JsonSerializable()
class Car {
  const Car({
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
  });

  final String brand;
  final String model;
  final int year;
  final String color;
}
