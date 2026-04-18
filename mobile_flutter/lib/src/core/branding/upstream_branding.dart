const String appName = 'ColorManager';
const String appDisplayName = 'Color Library Manager';
const String appVersion = '1.0.1';
const String appAuthor = 'Alsophila';
const String appTagline = 'For academic exchange only, app is free of charge';
const String antiResaleMessage =
  'If you paid for this software, request a refund and report the seller';
const String nonCommercialNotice =
  'PolyForm Noncommercial 1.0.0 | Commercial use requires explicit author permission';

final String exportNameSuffix =
    '_free_by_${appAuthor.substring(0, 1).toLowerCase()}';

String buildExportColorName(String? name, int index) {
  final candidate = (name ?? '').trim();
  final baseName = candidate.isEmpty ? 'Color $index' : candidate;
  if (baseName.endsWith(exportNameSuffix)) {
    return baseName;
  }
  return '$baseName$exportNameSuffix';
}

List<String> buildStatusRotationMessages() {
  return <String>[
    'Ver $appVersion | Author: $appAuthor | $appTagline',
    'Ver $appVersion | $antiResaleMessage',
    nonCommercialNotice,
  ];
}
