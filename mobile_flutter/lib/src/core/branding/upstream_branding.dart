const String appName = 'ColorManager';
const String appDisplayName = 'Color Library Manager';
const String appVersion = '1.0.1';
const String appAuthor = 'Alsophila';
const String appTagline = '仅限学术交流，完全免费';
const String antiResaleMessage = '若您为本软件付费，请立即退款并举报卖家';
const String nonCommercialNotice = 'PolyForm Noncommercial 1.0.0 | 商业使用需作者明确许可';

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
