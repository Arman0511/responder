// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AdminImpl _$$AdminImplFromJson(Map<String, dynamic> json) => _$AdminImpl(
      name: json['name'] as String,
      email: json['email'] as String,
      uid: json['uid'] as String,
      phonenumber: json['phonenumber'] as String,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$$AdminImplToJson(_$AdminImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'uid': instance.uid,
      'phonenumber': instance.phonenumber,
      'image': instance.image,
    };
