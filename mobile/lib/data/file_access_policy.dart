/// App-level file access contract used by both Android and iOS implementations.
///
/// This policy intentionally keeps the app signing-agnostic and entitlement-agnostic
/// for core workflows. Any capability tied to a specific profile should remain
/// an optional enhancement rather than a hard dependency.
class FileAccessPolicy {
  const FileAccessPolicy._();

  static const String workspaceRootName = 'ColorManager';
  static const String materialsFolderName = 'materials';
  static const String libraryFolderName = 'library';

  static const List<String> workspaceFolders = <String>[
    materialsFolderName,
    libraryFolderName,
  ];
}

class AndroidStoragePolicy {
  const AndroidStoragePolicy._();

  /// SAF tree URI access is the primary and expected path.
  static const bool useSafTreeAccess = true;

  /// Must stay false to avoid over-privileged storage access.
  static const bool allowManageExternalStorage = false;

  /// Must stay false in default flow; only request when explicitly needed.
  static const bool requireBroadMediaPermissionByDefault = false;

  /// When SAF authorization is not granted, app should continue with private storage.
  static const bool allowPrivateStorageFallback = true;
}

class IosFilePolicy {
  const IosFilePolicy._();

  /// Core file import should work without iCloud container entitlements.
  static const bool requireICloudContainer = false;

  /// External files are copied into sandbox for deterministic processing.
  static const bool copyImportsIntoSandboxByDefault = true;

  /// Core flow should not assume a fixed bundle identifier or team identifier.
  static const bool signingAgnosticCoreFlow = true;
}
