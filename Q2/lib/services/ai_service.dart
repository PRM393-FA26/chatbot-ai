import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // Điền API Key của bạn vào đây
  static const String _apiKey = 'YOUR_API_KEY_HERE'; // Ta có thể thay bằng key thật (lên google ai studio mà tạo key)

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent'; // Đối với cái này thì ta có thể tủy chỉnh với các model khác, hoặc với chính bản thân gemini

  static Future<String> sendMessage(String prompt) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    // Header cấu hình gửi định dạng JSON
    final headers = {
      'Content-Type': 'application/json',
    };

    // Body payload theo cấu trúc Gemini API
    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // Bóc tách JSON đa tầng
        final data = jsonDecode(response.body);
        final String replyText =
        data['candidates'][0]['content']['parts'][0]['text'];
        return replyText.trim();
      } else {
        return 'Lỗi server (${response.statusCode}): ${response.reasonPhrase}';
      }
    } catch (e) {
      // Bắt ngoại lệ lỗi mạng (SocketException, timeout,...)
      return 'Lỗi kết nối mạng: Vui lòng kiểm tra internet của bạn.';
    }
  }
}