/// Cleans the content to ensure it's valid JSON without markdown or code tags
String cleanJsonContent(String content) {
  String cleaned = content;

  // Remove ```json and ``` markers
  cleaned = cleaned.replaceAll(RegExp(r'```json\s*'), '');
  cleaned = cleaned.replaceAll(RegExp(r'```\s*$'), '');
  cleaned = cleaned.replaceAll('```', '');

  // Remove any leading/trailing whitespace
  return cleaned.trim();
}
