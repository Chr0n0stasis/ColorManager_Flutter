class WorkspaceFolderPolicy {
  const WorkspaceFolderPolicy._();

  static const String workspaceRootName = 'ColorManager';
  static const String materialsFolderName = 'materials';
  static const String libraryFolderName = 'library';

  static const List<String> requiredFolders = <String>[
    materialsFolderName,
    libraryFolderName,
  ];
}

class AndroidLeastPrivilegePolicy {
  const AndroidLeastPrivilegePolicy._();

  /// SAF tree URI is the primary write/read access route.
  static const bool useSafTreeUri = true;

  /// Never rely on all-files access for normal operation.
  static const bool allowManageExternalStorage = false;

  /// No broad media/storage permission as default blocker.
  static const bool broadReadPermissionAsDefault = false;

  /// App can keep running when SAF permission is missing.
  static const bool allowPrivateStorageFallback = true;
}

class IosSigningAgnosticPolicy {
  const IosSigningAgnosticPolicy._();

  /// Core flow should not require iCloud containers.
  static const bool requireICloudContainer = false;

  /// Default import mode: copy external files into sandbox for deterministic behavior.
  static const bool copyImportsToSandboxByDefault = true;

  /// Core features should remain independent from fixed app id/team id assumptions.
  static const bool signingAgnosticCoreFlow = true;

  /// Release signatures are provided externally; app logic must not depend on signer type.
  static const bool externalSigningSupported = true;
}
