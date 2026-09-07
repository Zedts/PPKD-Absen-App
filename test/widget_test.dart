import 'package:flutter_test/flutter_test.dart';
import 'package:ppkd_absen_app/app.dart';
import 'package:ppkd_absen_app/core/services/dio_client.dart';
import 'package:ppkd_absen_app/core/services/secure_storage_service.dart';

void main() {
  testWidgets('App smoke test - verifies initial WelcomeScreen',
      (WidgetTester tester) async {
    final storage = SecureStorageService();
    final dioClient = DioClient(storage);

    await tester.pumpWidget(
      PpkdAbsenApp(
        storageService: storage,
        dioClient: dioClient,
      ),
    );

    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('SIGN UP'), findsOneWidget);
  });
}
