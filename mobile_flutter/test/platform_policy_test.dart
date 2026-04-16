import 'package:color_manager_mobile/src/platform/file_access_policies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Platform policy contract', () {
    test('android least privilege is enforced by defaults', () {
      expect(AndroidLeastPrivilegePolicy.useSafTreeUri, isTrue);
      expect(AndroidLeastPrivilegePolicy.allowManageExternalStorage, isFalse);
      expect(AndroidLeastPrivilegePolicy.broadReadPermissionAsDefault, isFalse);
      expect(AndroidLeastPrivilegePolicy.allowPrivateStorageFallback, isTrue);
    });

    test('ios flow is signing-agnostic and sandbox-first', () {
      expect(IosSigningAgnosticPolicy.requireICloudContainer, isFalse);
      expect(IosSigningAgnosticPolicy.copyImportsToSandboxByDefault, isTrue);
      expect(IosSigningAgnosticPolicy.signingAgnosticCoreFlow, isTrue);
      expect(IosSigningAgnosticPolicy.externalSigningSupported, isTrue);
    });

    test('workspace requires materials and library folders', () {
      expect(WorkspaceFolderPolicy.workspaceRootName, 'ColorManager');
      expect(WorkspaceFolderPolicy.requiredFolders, contains('materials'));
      expect(WorkspaceFolderPolicy.requiredFolders, contains('library'));
    });
  });
}
