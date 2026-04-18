import 'package:color_manager_mobile/color_manager_core.dart';
import 'package:color_manager_mobile/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ColorManager app boots with shell title', (tester) async {
    await tester.pumpWidget(const ColorManagerMobileApp());
    await tester.pumpAndSettle();

    expect(find.text('$appDisplayName $appVersion'), findsOneWidget);
    expect(find.text('Materials'), findsWidgets);
  });
}
