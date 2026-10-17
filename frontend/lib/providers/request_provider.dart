import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/event_request_model.dart';

class RequestProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<EventRequestModel> _customerRequests = [];
  EventRequestModel? _currentRequest;
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastCreatedCompletionCode;

  List<EventRequestModel> get customerRequests => _customerRequests;
  EventRequestModel? get currentRequest => _currentRequest;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get lastCreatedCompletionCode => _lastCreatedCompletionCode;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearLastCreatedCompletionCode() {
    _lastCreatedCompletionCode = null;
    notifyListeners();
  }

  Future<bool> fetchCustomerRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConfig.requestList);
      if (res is Map && res['requests'] is List) {
        final list = res['requests'] as List;
        _customerRequests = list
            .map((item) => EventRequestModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _customerRequests = [];
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
      _errorMessage = 'Failed to load requests';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchRequestById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get(ApiConfig.requestDetail(id));
      if (res is Map && res['request'] != null) {
        _currentRequest = EventRequestModel.fromJson(res['request']);
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
      _errorMessage = 'Failed to load request details';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> createRequest({
    required String eventDetails,
    required double pay,
    required String city,
    required String pincode,
    required String state,
    required String location,
    required String category,
    required String time,
    required DateTime startTime,
    required DateTime endTime,
    required int noOfCandidates,
    required DateTime date,
    String additionalDescription = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _lastCreatedCompletionCode = null;
    notifyListeners();

    try {
      final body = {
        'event_details': eventDetails.trim(),
        'pay': pay,
        'city': city.trim(),
        'pincode': pincode.trim(),
        'state': state.trim(),
        'location': location.trim(),
        'category': category.trim(),
        'time': time.trim(),
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'no_of_candidates': noOfCandidates,
        'date': date.toIso8601String(),
        'additional_description': additionalDescription.trim(),
      };

      final res = await _api.post(ApiConfig.requestCreate, body: body);

      String? code;
      if (res is Map) {
        code = res['completion_code']?.toString();
        _lastCreatedCompletionCode = code;
        if (res['request'] != null) {
          final newReq = EventRequestModel.fromJson(res['request']);
          _customerRequests.insert(0, newReq);
        }
      }

      _isLoading = false;
      notifyListeners();
      return code ?? 'Created';
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to create event request';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> freelancerAccept(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post(ApiConfig.freelancerAcceptRequest(requestId));
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to accept request';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> freelancerReject(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post(ApiConfig.freelancerRejectRequest(requestId));
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to reject request';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitAttendance(String requestId, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post(
        ApiConfig.freelancerAttendance(requestId),
        body: {'code': code.trim()},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit attendance code';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitRedflag(String requestId, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.post(
        ApiConfig.freelancerRedFlag(requestId),
        body: {'code': code.trim()},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit red flag';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> remindAttendance(String requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post(
        '${ApiConfig.baseUrl}/api/request/$requestId/remind-attendance',
      );
      _isLoading = false;
      notifyListeners();
      return res is Map ? res['message']?.toString() : 'Reminders sent';
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to send reminders';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> removeFreelancerFromAccepted(
      String requestId, String freelancerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.delete(
        '${ApiConfig.baseUrl}/api/request/$requestId/freelancer/$freelancerId',
      );
      
      // Remove from current request's accepted list
      if (_currentRequest != null) {
        final updated = _currentRequest!.acceptedFreelancers
            .where((f) => f['_id'] != freelancerId)
            .toList();
        _currentRequest = EventRequestModel(
          id: _currentRequest!.id,
          customerId: _currentRequest!.customerId,
          eventDetails: _currentRequest!.eventDetails,
          pay: _currentRequest!.pay,
          city: _currentRequest!.city,
          pincode: _currentRequest!.pincode,
          state: _currentRequest!.state,
          location: _currentRequest!.location,
          category: _currentRequest!.category,
          time: _currentRequest!.time,
          startTime: _currentRequest!.startTime,
          endTime: _currentRequest!.endTime,
          noOfCandidates: _currentRequest!.noOfCandidates,
          date: _currentRequest!.date,
          additionalDescription: _currentRequest!.additionalDescription,
          completionCode: _currentRequest!.completionCode,
          createdAt: _currentRequest!.createdAt,
          acceptedFreelancers: updated,
        );
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
      _errorMessage = 'Failed to remove freelancer';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
