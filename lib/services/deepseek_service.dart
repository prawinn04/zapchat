import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const String _baseUrl = 'https://router.huggingface.co/v1/chat/completions';
  
  final String _apiKey;

  DeepSeekService() : _apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';

  /// Stream chat completion from HuggingFace Router API
  Stream<String> streamChatCompletion({
    required String message,
    required String systemPrompt,
    required List<Map<String, String>> conversationHistory,
  }) async* {
    if (_apiKey.isEmpty) {
      throw Exception('API key not found. Please check your .env file.');
    }

    try {
      // Prepare messages for OpenAI-compatible API
      final messages = <Map<String, String>>[];
      
      if (systemPrompt.isNotEmpty) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }
      
      // Add conversation history
      messages.addAll(conversationHistory);
      
      // Add current message
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'google/gemma-2-2b-it',
          'messages': messages,
          'max_tokens': 150,
          'temperature': 0.7,
          'stream': false, // Use non-streaming for now to simplify
        }),
      );

      if (response.statusCode != 200) {
        // Fallback response for testing
        yield 'Hello! I\'m having trouble connecting to the AI service right now, but I can still chat with you. How can I help?';
        return;
      }

      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse['choices'] != null && jsonResponse['choices'].isNotEmpty) {
        final content = jsonResponse['choices'][0]['message']['content'] as String? ?? '';
        
        if (content.isNotEmpty) {
          // Stream the response word by word for better UX
          final words = content.trim().split(' ');
          for (int i = 0; i < words.length; i++) {
            yield words[i] + (i < words.length - 1 ? ' ' : '');
            // Small delay between words for streaming effect
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } else {
          yield 'Hello! How can I help you today?';
        }
      } else {
        yield 'Hello! How can I help you today?';
      }
    } catch (e) {
      throw Exception('Failed to get chat completion: $e');
    }
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'google/gemma-2-2b-it',
          'messages': [
            {'role': 'user', 'content': 'Hello'}
          ],
          'max_tokens': 10,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}