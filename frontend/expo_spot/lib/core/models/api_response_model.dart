import 'package:expo_spot/core/json/json_readers.dart';

/// Mirrors `com.nawaf.meetingpoint.Api.ApiResponse`.
class ApiResponseModel {
  const ApiResponseModel({required this.message});

  final String message;

  factory ApiResponseModel.fromJson(Map<String, dynamic> json) {
    return ApiResponseModel(
      message: JsonReaders.stringValue(json['message']),
    );
  }

  Map<String, dynamic> toJson() => {'message': message};
}
