import 'package:flutter_test/flutter_test.dart';
import 'package:pos_cloud/main.dart';

void main() {
  testWidgets('App loads login', (tester) async {
    await tester.pumpWidget(const PosApp());
    expect(find.text('POS Cloud'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
