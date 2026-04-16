import 'package:color_manager_mobile/src/ui/layout_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Layout contract', () {
    test('semantic order matches desktop anchor order', () {
      expect(
        LayoutContract.semanticOrder,
        const <LayoutAnchorZone>[
          LayoutAnchorZone.materials,
          LayoutAnchorZone.detail,
          LayoutAnchorZone.composePreview,
        ],
      );
    });

    test('breakpoints are ordered compact < medium < expanded', () {
      expect(LayoutContract.mediumBreakpoint, lessThan(LayoutContract.expandedBreakpoint));
      expect(LayoutContract.mediumBreakpoint, greaterThan(0));
    });

    test('flex groups keep three-zone balance', () {
      final expandedTotal =
          LayoutContract.expandedLeftFlex + LayoutContract.expandedCenterFlex + LayoutContract.expandedRightFlex;
      final mediumTotal =
          LayoutContract.mediumLeftFlex + LayoutContract.mediumCenterFlex + LayoutContract.mediumRightFlex;
      expect(expandedTotal, greaterThan(0));
      expect(mediumTotal, greaterThan(0));
    });
  });
}
