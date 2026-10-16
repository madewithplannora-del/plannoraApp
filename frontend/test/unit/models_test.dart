import 'package:flutter_test/flutter_test.dart';
import 'package:planera/models/customer_model.dart';
import 'package:planera/models/event_request_model.dart';
import 'package:planera/models/freelancer_model.dart';
import 'package:planera/models/notification_model.dart';
import 'package:planera/models/user_model.dart';

void main() {
  group('UserModel Serialization', () {
    test('UserModel.fromJson parses successfully', () {
      final json = {
        'id': '6ad1e2bd0f3eb098c2dd4ea0',
        'username': 'krishnraj shivolkar',
        'email': 'krishnrajshivolkar@gmail.com',
        'emailVerified': true,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '6ad1e2bd0f3eb098c2dd4ea0');
      expect(user.username, 'krishnraj shivolkar');
      expect(user.email, 'krishnrajshivolkar@gmail.com');
      expect(user.emailVerified, true);
    });

    test('UserModel handles _id fallback', () {
      final json = {
        '_id': 'mongo_object_id_123',
        'username': 'testuser',
        'email': 'test@example.com',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'mongo_object_id_123');
      expect(user.emailVerified, false);
    });
  });

  group('CustomerModel Serialization', () {
    test('CustomerModel.fromJson parses with account and profilePicture map', () {
      final json = {
        '_id': 'cust_123',
        'account': 'user_456',
        'phoneno': '9876543210',
        'state': 'Goa',
        'city': 'Panaji',
        'pincode': '403001',
        'profilePicture': {
          'url': 'https://ik.imagekit.io/plannora/cust.jpg',
          'fileId': 'img_001',
        },
      };

      final customer = CustomerModel.fromJson(json);

      expect(customer.id, 'cust_123');
      expect(customer.accountId, 'user_456');
      expect(customer.phoneno, '9876543210');
      expect(customer.state, 'Goa');
      expect(customer.city, 'Panaji');
      expect(customer.pincode, '403001');
      expect(customer.profilePictureUrl, 'https://ik.imagekit.io/plannora/cust.jpg');
      expect(customer.profilePictureFileId, 'img_001');
    });
  });

  group('FreelancerModel Serialization', () {
    test('FreelancerModel.fromJson parses with category and linkedin', () {
      final json = {
        '_id': 'free_123',
        'userId': 'user_789',
        'phone': '9123456789',
        'category': 'Professional',
        'state': 'Maharashtra',
        'city': 'Mumbai',
        'pincode': '400001',
        'linkedin': 'https://linkedin.com/in/pro',
        'profilePicture': {
          'url': 'https://ik.imagekit.io/plannora/free.jpg',
          'publicId': 'pub_123',
        },
      };

      final freelancer = FreelancerModel.fromJson(json);

      expect(freelancer.id, 'free_123');
      expect(freelancer.userId, 'user_789');
      expect(freelancer.category, 'Professional');
      expect(freelancer.linkedin, 'https://linkedin.com/in/pro');
      expect(freelancer.profilePictureUrl, 'https://ik.imagekit.io/plannora/free.jpg');
    });
  });

  group('EventRequestModel Serialization', () {
    test('EventRequestModel.fromJson parses complete request data', () {
      final json = {
        '_id': 'req_999',
        'customer': 'cust_123',
        'event_details': 'Tech Expo Hospitality Host',
        'pay': 4500,
        'city': 'Panaji',
        'pincode': '403001',
        'state': 'Goa',
        'location': 'Kala Academy',
        'category': 'Professional',
        'time': '10:00 AM - 06:00 PM',
        'no_of_candidates': 3,
        'date': '2026-11-20T00:00:00.000Z',
        'additional_description': 'Formal dress code required',
        'completion_code': '982341',
      };

      final event = EventRequestModel.fromJson(json);

      expect(event.id, 'req_999');
      expect(event.eventDetails, 'Tech Expo Hospitality Host');
      expect(event.pay, 4500.0);
      expect(event.city, 'Panaji');
      expect(event.noOfCandidates, 3);
      expect(event.category, 'Professional');
      expect(event.completionCode, '982341');
      expect(event.additionalDescription, 'Formal dress code required');
    });
  });

  group('NotificationModel Serialization', () {
    test('NotificationModel.fromJson parses notification with type and read status', () {
      final json = {
        '_id': 'notif_1',
        'title': 'New Event Match',
        'message': 'A new Cultural event has been broadcast in your city',
        'type': 'GENERAL',
        'read': false,
        'createdAt': '2026-10-16T12:00:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);

      expect(notif.id, 'notif_1');
      expect(notif.title, 'New Event Match');
      expect(notif.read, false);
      expect(notif.type, 'GENERAL');
    });
  });
}
