class AdminResponse {
  final bool success;
  final List<dynamic> data;
  final int total;
  final int page;
  final int totalPages;

  AdminResponse({
    required this.success,
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory AdminResponse.fromJson(Map<String, dynamic> json) {
    return AdminResponse(
      success: json['success'],
      data: json['data'], // List of admin objects
      total: json['total'],
      page: json['page'],
      totalPages: json['totalPages'],
    );
  }
}