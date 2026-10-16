class FreelancerModel {
  final String id;
  final String userId;
  final String phone;
  final String category;
  final String state;
  final String city;
  final String pincode;
  final String linkedin;
  final String? profilePictureUrl;
  final String? profilePicturePublicId;

  FreelancerModel({
    required this.id,
    required this.userId,
    required this.phone,
    required this.category,
    required this.state,
    required this.city,
    required this.pincode,
    required this.linkedin,
    this.profilePictureUrl,
    this.profilePicturePublicId,
  });

  factory FreelancerModel.fromJson(Map<String, dynamic> json) {
    String? picUrl;
    String? picId;

    if (json['profilePicture'] is Map) {
      picUrl = json['profilePicture']['url']?.toString();
      picId = json['profilePicture']['publicId']?.toString();
    } else if (json['profilePicture'] is String) {
      picUrl = json['profilePicture'];
    }

    return FreelancerModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId'] is Map
          ? (json['userId']['_id']?.toString() ?? '')
          : (json['userId']?.toString() ?? ''),
      phone: json['phone']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Professional',
      state: json['state']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      linkedin: json['linkedin']?.toString() ?? '',
      profilePictureUrl: picUrl,
      profilePicturePublicId: picId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'phone': phone,
      'category': category,
      'state': state,
      'city': city,
      'pincode': pincode,
      'linkedin': linkedin,
      'profilePicture': {
        'url': profilePictureUrl,
        'publicId': profilePicturePublicId,
      },
    };
  }
}
