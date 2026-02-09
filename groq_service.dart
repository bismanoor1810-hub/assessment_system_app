import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  // Aapki API Key
  final String _apiKey = "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";
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";

  Future<String> getAIAnalysis(List<String> studentComments) async {
    if (studentComments.isEmpty) return "Abhi tak kisi peer ne comment nahi kiya.";

    // Saare comments ko ek jagah jama karna
    String allComments = studentComments.map((c) => "• $c").join("\n");

    final prompt = """
    Below are feedback comments from peers for a student's presentation. 
    Analyze them and provide:
    1. A very brief summary (2 lines max) of what they did well and where they lacked.
    2. One clear 'AI Mentor Tip' for their next presentation.
    Keep the tone very encouraging and professional.
    
    Student Peer Comments:
    $allComments
    """;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": "You are a helpful academic mentor and communication expert."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.6, // Thoda creative summary ke liye
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "AI analysis thoda late hai, tab tak aap khud comments parh lein!";
      }
    } catch (e) {
      return "Internet connection check karein, AI connect nahi ho pa raha.";
    }
  }
}