import 'package:flutter_test/flutter_test.dart';
import 'package:umkm_pembukuan/main.dart';

void main() {
  testWidgets('App starts and shows Dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const UmkmApp());

    // Cek judul tab pertama (Dashboard) muncul
    expect(find.text('Dashboard'), findsOneWidget);
  });
}