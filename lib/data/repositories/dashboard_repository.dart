import 'package:dio/dio.dart';
import 'package:musamimuk/core/network/api_client.dart';
import 'package:musamimuk/core/network/api_utils.dart';
import 'package:musamimuk/data/models/dashboard_models.dart';

sealed class DashboardResult {}

class DashboardSuccess extends DashboardResult {
  final String? message;
  final AdminDashboardData? admin;
  final RevenueDashboardData? revenue;
  DashboardSuccess({this.message, this.admin, this.revenue});
}

class DashboardFailure extends DashboardResult {
  final String message;
  DashboardFailure(this.message);
}

class DashboardRepository {
  DashboardRepository() : _api = ApiClient();

  final ApiClient _api;

  Future<DashboardResult> adminDashboard() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('admin/dashboard');
      final data = response.data;
      if (data == null) return DashboardFailure('Empty response');
      return DashboardSuccess(
        admin: AdminDashboardData.fromJson(data),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return DashboardFailure(apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error');
    } catch (_) {
      return DashboardFailure('Something went wrong');
    }
  }

  Future<DashboardResult> revenueDashboard() async {
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('revenues/dashboard');
      final data = response.data;
      if (data == null) return DashboardFailure('Empty response');
      return DashboardSuccess(
        revenue: RevenueDashboardData.fromJson(data),
        message: apiExtractMessage(data),
      );
    } on DioException catch (e) {
      return DashboardFailure(apiExtractMessage(e.response?.data) ?? e.message ?? 'Network error');
    } catch (_) {
      return DashboardFailure('Something went wrong');
    }
  }
}

