class CustomerModel {
  final String id;
  final String accountId;
  final String phoneno;
  final String state;
  final String city;
  final String pincode;
  final String? profilePictureUrl;
  final String? profilePictureFileId;

  CustomerModel({
    required this.id,
    required this.accountId,
    required this.phoneno,
    required this.state,
    required this.city,
    required this.pincode,
    this.profilePictureUrl,
    this.profilePictureFileId,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    String? picUrl;
    String? picId;

    if (json['profilePicture'] is Map) {
      picUrl = json['profilePicture']['url']?.toString();
      picId = (json['profilePicture']['fileId'] ??
              json['profilePicture']['publicId'])
          ?.toString();
    } else if (json['profilePicture'] is String) {
      picUrl = json['profilePicture'];
    }

    final acc = json['account'] ?? json['userId'];
    final accId = acc is Map ? (acc['_id']?.toString() ?? '') : (acc?.toString() ?? '');

    return CustomerModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      accountId: accId,
      phoneno: json['phoneno']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      profilePictureUrl: picUrl,
      profilePictureFileId: picId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account': accountId,
      'phoneno': phoneno,
      'state': state,
      'city': city,
      'pincode': pincode,
      'profilePicture': {
        'url': profilePictureUrl,
        'fileId': profilePictureFileId,
      },
    };
  }
}
