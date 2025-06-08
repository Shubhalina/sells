import 'package:postgres/postgres.dart';

class DatabaseService {
  final PostgreSQLConnection _connection;

  DatabaseService(String host, int port, String databaseName, String username, String password)
      : _connection = PostgreSQLConnection(host, port, databaseName, username: username, password: password);

  Future<void> connect() async {
    await _connection.open();
  }

  Future<void> close() async {
    await _connection.close();
  }

  // Payment related methods
  Future<void> savePayment(Map<String, dynamic> paymentData) async {
    await _connection.query(
      'INSERT INTO payments (offer_id, amount, payment_method, status, created_at) '
      'VALUES (@offerId, @amount, @paymentMethod, @status, @createdAt)',
      substitutionValues: {
        'offerId': paymentData['offerId'],
        'amount': paymentData['amount'],
        'paymentMethod': paymentData['paymentMethod'],
        'status': 'completed',
        'createdAt': DateTime.now(),
      },
    );
  }

  // Shipping related methods
  Future<void> saveShippingDetails(Map<String, dynamic> shippingData) async {
    await _connection.query(
      'INSERT INTO shipping (offer_id, courier, tracking_number, shipping_date, estimated_delivery) '
      'VALUES (@offerId, @courier, @trackingNumber, @shippingDate, @estimatedDelivery)',
      substitutionValues: {
        'offerId': shippingData['offerId'],
        'courier': shippingData['courier'],
        'trackingNumber': shippingData['trackingNumber'],
        'shippingDate': shippingData['shippingDate'],
        'estimatedDelivery': shippingData['estimatedDelivery'],
      },
    );
  }

  // Feedback related methods
  Future<void> saveFeedback(Map<String, dynamic> feedbackData) async {
    await _connection.query(
      'INSERT INTO feedback (offer_id, rating, comments, created_at) '
      'VALUES (@offerId, @rating, @comments, @createdAt)',
      substitutionValues: {
        'offerId': feedbackData['offerId'],
        'rating': feedbackData['rating'],
        'comments': feedbackData['comments'],
        'createdAt': DateTime.now(),
      },
    );
  }
}