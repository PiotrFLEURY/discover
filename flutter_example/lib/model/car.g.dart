// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Car _$CarFromJson(Map<String, dynamic> json) => Car(
  brand: json['brand'] as String,
  model: json['model'] as String,
  year: (json['year'] as num).toInt(),
  color: json['color'] as String,
);

Map<String, dynamic> _$CarToJson(Car instance) => <String, dynamic>{
  'brand': instance.brand,
  'model': instance.model,
  'year': instance.year,
  'color': instance.color,
};
