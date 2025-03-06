/// Cleans the content to ensure it's valid JSON without markdown or code tags
String cleanJsonContent(String content) {
  // Remove markdown code blocks
  var cleaned = content.replaceAll(RegExp(r'```json|```'), '');
  
  // Remove any leading/trailing whitespace
  cleaned = cleaned.trim();
  
  // If the content is wrapped in quotes, remove them
  if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
    cleaned = cleaned.substring(1, cleaned.length - 1);
  }
  
  // Unescape escaped quotes
  cleaned = cleaned.replaceAll(r'\"', '"');
  
  return cleaned;
} 