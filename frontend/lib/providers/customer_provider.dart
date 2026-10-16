import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/customer_model.dart';

class CustomerProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  CustomerModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasChecked = false;

  CustomerModel? get profile => _profile;
  bool get hasProfile => _profile != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasChecked => _hasChecked;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConfig.customerProfile);
      if (res is Map && res['customer'] != null) {
        _profile = CustomerModel.fromJson(res['customer']);
        _hasChecked = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _profile = null;
      _hasChecked = true;
      _isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _profile = null;
      } else {
        _errorMessage = e.message;
      }
      _hasChecked = true;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to load customer profile';
      _hasChecked = true;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createProfile({
    required String phoneno,
    required String state,
    required String city,
    required String pincode,
    String? imagePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fields = {
        'phoneno': phoneno.trim(),
        'state': state.trim(),
        'city': city.trim(),
        'pincode': pincode.trim(),
      };

      final res = await _api.multipartRequest(
        method: 'POST',
        path: ApiConfig.customerCreate,
        fields: fields,
        fileField: 'image',
        filePath: imagePath,
      );

      if (res is Map && res['customer'] != null) {
        _profile = CustomerModel.fromJson(res['customer']);
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
      _errorMessage = 'Failed to create customer profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String phoneno,
    required String state,
    required String city,
    required String pincode,
    String? imagePath,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fields = {
        'phoneno': phoneno.trim(),
        'state': state.trim(),
        'city': city.trim(),
        'pincode': pincode.trim(),
      };

      final res = await _api.multipartRequest(
        method: 'PUT',
        path: ApiConfig.customerUpdate,
        fields: fields,
        fileField: 'image',
        filePath: imagePath,
      );

      if (res is Map && res['customer'] != null) {
        _profile = CustomerModel.fromJson(res['customer']);
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
      _errorMessage = 'Failed to update customer profile';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _profile = null;
    _isLoading = false;
    _errorMessage = null;
    _hasChecked = false;
    notifyListeners();
  }
}
