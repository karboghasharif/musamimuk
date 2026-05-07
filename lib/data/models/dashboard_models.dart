import 'package:musamimuk/core/network/api_utils.dart';

class AdminDashboardData {
  final Map<String, dynamic> raw;
  const AdminDashboardData(this.raw);

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final dbData = apiExtractDbData(json);
    if (dbData is Map) return AdminDashboardData(dbData.cast<String, dynamic>());
    return AdminDashboardData(json);
  }
}

class RevenueDashboardData {
  final Map<String, dynamic> raw;
  const RevenueDashboardData(this.raw);

  factory RevenueDashboardData.fromJson(Map<String, dynamic> json) {
    final dbData = apiExtractDbData(json);
    if (dbData is Map) return RevenueDashboardData(dbData.cast<String, dynamic>());
    return RevenueDashboardData(json);
  }
}

