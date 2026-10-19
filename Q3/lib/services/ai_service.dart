import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class AiService {
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent';

  // System Message đặt rào chắn Guardrails cho AI
  static const String _systemInstruction = '''
Bạn là một Trợ lý Hướng dẫn viên Du lịch chuyên nghiệp, thân thiện và am hiểu văn hóa.

PHẠM VI CHO PHÉP:
- Bạn CHỈ TƯ VẤN các chủ đề liên quan đến du lịch: địa điểm tham quan, lịch trình chuyến đi, ẩm thực địa phương, phương tiện di chuyển, kinh nghiệm du lịch, văn hóa và lễ hội.

QUY TẮC BẮT BỘC (GUARDRAILS):
- Nếu người dùng hỏi bất kỳ chủ đề nào KHÔNG liên quan đến du lịch (ví dụ: viết code lập trình, giải toán, thời sự, bóng đá, làm thơ tình, hỏi đáp kiến thức chung...), bạn BẮT BUỘC phải từ chối một cách lịch sự.
- Mẫu từ chối: "Xin lỗi bạn, tôi là trợ lý chuyên về du lịch nên chỉ có thể hỗ trợ các câu hỏi liên quan đến địa điểm, ẩm thực, lịch trình và kinh nghiệm chuyến đi. Bạn có cần tôi gợi ý điểm đến hay món ăn ngon nào không?"
''';

  static Future<String> sendMultiTurnMessage(List<ChatMessage> history) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    final headers = {'Content-Type': 'application/json'};

    // Biến đổi danh sách lịch sử tin nhắn sang định dạng API Gemini hỗ trợ Multi-turn
    final List<Map<String, dynamic>> contents = history.map((msg) {
      return {
        "role": msg.isUser ? "user" : "model",
        "parts": [
          {"text": msg.text}
        ]
      };
    }).toList();

    // Request body bao gồm System Instruction + Lịch sử hội thoại
    final body = jsonEncode({
      "system_instruction": {
        "parts": [
          {"text": _systemInstruction}
        ]
      },
      "contents": contents,
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String replyText =
        data['candidates'][0]['content']['parts'][0]['text'];
        return replyText.trim();
      }
      // Xử lý các mã lỗi nâng cao theo yêu cầu đề bài
      else if (response.statusCode == 429) {
        return '⚠️ Hệ thống đang quá tải lượt gọi (HTTP 429 - Rate Limit). Vui lòng đợi ít phút rồi thử lại!';
      } else if (response.statusCode == 503) {
        return '⚠️ Máy chủ AI hiện đang bảo trì hoặc quá tải (HTTP 503). Vui lòng thử lại sau!';
      } else {
        return '⚠️ Lỗi máy chủ (${response.statusCode}): ${response.reasonPhrase}';
      }
    } catch (e) {
      return '⚠️ Lỗi kết nối mạng: Vui lòng kiểm tra lại đường truyền internet.';
    }
  }
}