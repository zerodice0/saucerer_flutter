// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_master_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IngredientMasterModel _$IngredientMasterModelFromJson(
  Map<String, dynamic> json,
) => _IngredientMasterModel(
  id: json['id'] as String,
  name: json['name'] as String,
  categoryId: json['categoryId'] as String,
  category: json['category'] as String?,
  subCategory: json['subCategory'] as String?,
  description: json['description'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$IngredientMasterModelToJson(
  _IngredientMasterModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'categoryId': instance.categoryId,
  'category': instance.category,
  'subCategory': instance.subCategory,
  'description': instance.description,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'usageCount': instance.usageCount,
};
