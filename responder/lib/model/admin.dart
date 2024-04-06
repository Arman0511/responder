import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin.g.dart';
part 'admin.freezed.dart';

@Freezed()
class Admin with _$Admin {
  const factory Admin({
    required String name,
    required String email,
    required String uid,
    required String phonenumber,
    String? image,
  }) = _Admin;

  factory Admin.fromJson(Map<String, dynamic> json) => _$AdminFromJson(json);
}
