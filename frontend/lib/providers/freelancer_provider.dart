import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/freelancer_model.dart';

class FreelancerProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  FreelancerModel? _profile;
  Map<String, dynamic>? _details;
  Map<String, dynamic>? _progress;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChecked = false;

  FreelancerModel? get profile => _profile;
  bool get hasProfile => _profile != null;
  Map<String, dynamic>? get details => _details;
  Map<String, dynamic>? get progress => _progress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasChecked => _hasChecked;

  // Convenience getters for progress lists
  List<dynamic> get receivedRequestIds => _progress?['received'] as List<dynamic>? ?? [];
  List<dynamic> get acceptedRequestIds => _progress?['accepted'] as List<dynamic>? ?? [];
  List<dynamic> get attendedRequestIds => _progress?['attended'] as List<dynamic>? ?? [];
  List<dynamic> get rejectedRequestIds => _progress?['rejected'] as List<dynamic>? ?? [];
  List<dynamic> get redflagRequestIds => _progress?['redflag'] as List<dynamic>? ?? [];

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConfig.freelancerProfile);
      if (res is Map && res['freelancer'] != null) {
        _profile = FreelancerModel.fromJson(res['freelancer']);
        _details = res['details'] as Map<String, dynamic>?;
        _progress = res['progress'] as Map<String, dynamic>?;
        _hasChecked = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _profile = null;
      _details = null;
      _progress = null;
      _hasChecked = true;
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _profile = null;
        _details = null;
        _progress = null;
      } else {
        _errorMessage = e.message;
      }
      _hasChecked = true;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to load freelancer profile';
      _hasChecked = true;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createProfile({
    required String phone,
    required String category,
    required String state,
    required String city,
    required String pincode,
    required String linkedin,
    String? imagePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fields = {
        'phone': phone.trim(),
        'category': category.trim(),
        'state': state.trim(),
        'city': city.trim(),
        'pincode': pincode.trim(),
        'linkedin': linkedin.trim(),
      };

      final res = await _api.multipartRequest(
        method: 'POST',
        path: ApiConfig.freelancerCreate,
        fields: fields,
        fileField: 'image',
        filePath: imagePath,
      );

      if (res is Map && res['freelancer'] != null) {
        _profile = FreelancerModel.fromJson(res['freelancer']);
        await fetchProfile(); // load progress record
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create freelancer profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String phone,
    required String category,
    required String state,
    required String city,
    required String pincode,
    required String linkedin,
    String? imagePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fields = {
        'phone': phone.trim(),
        'category': category.trim(),
        'state': state.trim(),
        'city': city.trim(),
        'pincode': pincode.trim(),
        'linkedin': linkedin.trim(),
      };

      final res = await _api.multipartRequest(
        method: 'PUT',
        path: ApiConfig.freelancerUpdate,
        fields: fields,
        fileField: 'image',
        filePath: imagePath,
      );

      if (res is Map && res['freelancer'] != null) {
        _profile = FreelancerModel.fromJson(res['freelancer']);
      } else {
        await fetchProfile();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update freelancer profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _profile = null;
    _details = null;
    _progress = null;
    _isLoading = false;
    _errorMessage = null;
    _hasChecked = false;
    notifyListeners();
  }
}
