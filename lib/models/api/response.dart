class ApiError {
  final bool success;
  final String error;
  ApiError(this.success, this.error);

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      ApiError(json['success'] as bool, json['error'] as String);
}
