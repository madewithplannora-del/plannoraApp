class EventRequestModel {
  final String id;
  final String customerId;
  final String eventDetails;
  final double pay;
  final String city;
  final String pincode;
  final String state;
  final String location;
  final String category;
  final String time;
  final DateTime? startTime;
  final DateTime? endTime;
  final int noOfCandidates;
  final DateTime? date;
  final String additionalDescription;
  final String? completionCode;
  final DateTime? createdAt;

  EventRequestModel({
    required this.id,
    required this.customerId,
    required this.eventDetails,
    required this.pay,
    required this.city,
    required this.pincode,
    required this.state,
    required this.location,
    required this.category,
    required this.time,
    this.startTime,
    this.endTime,
    required this.noOfCandidates,
    this.date,
    this.additionalDescription = '',
    this.completionCode,
    this.createdAt,
  });

  factory EventRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final cust = json['customer'];
    final custId = cust is Map ? (cust['_id']?.toString() ?? '') : (cust?.toString() ?? '');

    return EventRequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      customerId: custId,
      eventDetails: json['event_details']?.toString() ?? '',
      pay: double.tryParse(json['pay']?.toString() ?? '0') ?? 0.0,
      city: json['city']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Professional',
      time: json['time']?.toString() ?? '',
      startTime: parseDate(json['start_time']),
      endTime: parseDate(json['end_time']),
      noOfCandidates: int.tryParse(json['no_of_candidates']?.toString() ?? '1') ?? 1,
      date: parseDate(json['date']),
      additionalDescription: json['additional_description']?.toString() ?? '',
      completionCode: json['completion_code']?.toString(),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customerId,
      'event_details': eventDetails,
      'pay': pay,
      'city': city,
      'pincode': pincode,
      'state': state,
      'location': location,
      'category': category,
      'time': time,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'no_of_candidates': noOfCandidates,
      'date': date?.toIso8601String(),
      'additional_description': additionalDescription,
    };
  }
}
