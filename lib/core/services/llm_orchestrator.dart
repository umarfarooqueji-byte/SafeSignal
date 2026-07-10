import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants.dart';
import '../models/ai_verdict.dart';
import 'local_rule_engine.dart';

/// LLM Orchestration Layer with circuit breaker + failover.
/// Priority: Gemini (primary) → GPT-class → Rule-engine (degraded)
class LlmOrchestrator {
  static final LlmOrchestrator _instance = LlmOrchestrator._internal();
  factory LlmOrchestrator() => _instance;
  LlmOrchestrator._internal();

  final _ruleEngine = LocalRuleEngine();
  final _dio = Dio();

  // Circuit breaker state per provider
  final Map<String, int> _failureCount = {};
  final Map<String, DateTime?> _circuitOpenedAt = {};
  static const int _failureThreshold = 3;
  static const Duration _circuitResetDuration = Duration(minutes: 2);

  // ─── Main entry point ──────────────────────────────────────────────────────
  Future<AiVerdict> analyze({
    required String text,
    required String type, // 'sms', 'url', 'chat'
    String language = 'hi',
  }) async {
    // Always run rule engine first (Tier 1 — instant, offline)
    final ruleVerdict = _ruleEngine.analyze(text, type: type);

    // If rule engine is very confident (>85), skip cloud
    if (ruleVerdict.confidence >= 0.90) {
      debugPrint('[LLM] High confidence from rule engine — skipping cloud');
      return ruleVerdict;
    }

    // Try cloud providers in order: Grok (primary) → Gemini (secondary)
    final providers = [
      _Provider(
        name: 'grok',
        analyze: (t, l) => _callGrok(t, l),
      ),
      _Provider(
        name: 'gemini',
        analyze: (t, l) => _callGemini(t, l),
      ),
    ];

    for (final provider in providers) {
      if (_isCircuitOpen(provider.name)) {
        debugPrint('[LLM] Circuit open for ${provider.name}, skipping');
        continue;
      }

      try {
        final verdict = await provider.analyze(text, language)
            .timeout(const Duration(seconds: 20));
        _recordSuccess(provider.name);
        return verdict.copyWith(provider: provider.name);
      } catch (e) {
        debugPrint('[LLM] ${provider.name} failed: $e');
        _recordFailure(provider.name);
      }
    }

    // All cloud providers failed → degraded mode with rule engine
    debugPrint('[LLM] All providers failed — using rule engine (degraded mode)');
    return ruleVerdict.copyWith(isOffline: true);
  }

  // ─── Gemini provider ───────────────────────────────────────────────────────
  Future<AiVerdict> _callGemini(String text, String language) async {
    final langName = language == 'hi'
        ? 'Hindi (Devanagari or Hinglish acceptable)'
        : 'English';

    const prompt = '''
You are SafeSignal — India's top AI cybersecurity expert. Analyze the following message/content for scams and fraud.

RESPOND ONLY WITH A VALID JSON OBJECT — no markdown, no code blocks:
{
  "verdict": "SCAM" or "SUSPICIOUS" or "SAFE",
  "riskScore": 0 to 100,
  "confidence": 0.0 to 1.0,
  "reasons": ["specific red flag 1", "specific red flag 2", "specific red flag 3"],
  "whatToDo": ["clear step 1", "clear step 2"],
  "summary": "2 sentence summary in plain language"
}
''';

    final systemPrompt = '$prompt\nWrite ALL text in $langName.\nAnalyze: ';

    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
      queryParameters: {'key': AppConstants.meshApiKey},
      data: {
        'contents': [
          {
            'parts': [
              {'text': systemPrompt + text}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 800,
        }
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    final content = response.data['candidates'][0]['content']['parts'][0]['text'] as String;

    // Clean response — remove markdown if any
    String jsonStr = content.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
    }

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AiVerdict.fromJson({...json, 'provider': 'gemini'});
  }

  // ─── Grok provider ─────────────────────────────────────────────────────────
  Future<AiVerdict> _callGrok(String text, String language) async {
    final langName = language == 'hi'
        ? 'Hindi (Devanagari or Hinglish acceptable)'
        : 'English';

    const prompt = '''
You are SafeSignal — India's top AI cybersecurity expert. Analyze the following message/content for scams and fraud.

RESPOND ONLY WITH A VALID JSON OBJECT — no markdown, no code blocks:
{
  "verdict": "SCAM" or "SUSPICIOUS" or "SAFE",
  "riskScore": 0 to 100,
  "confidence": 0.0 to 1.0,
  "reasons": ["specific red flag 1", "specific red flag 2", "specific red flag 3"],
  "whatToDo": ["clear step 1", "clear step 2"],
  "summary": "2 sentence summary in plain language"
}
''';

    final response = await _dio.post(
      'https://api.x.ai/v1/chat/completions',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.grokApiKey}',
        },
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
      data: {
        'model': 'grok-beta',
        'messages': [
          {'role': 'system', 'content': '$prompt\nWrite ALL text in $langName.'},
          {'role': 'user', 'content': 'Analyze this:\n$text'}
        ],
        'temperature': 0.1,
      },
    );

    final content = response.data['choices'][0]['message']['content'] as String;

    // Clean response
    String jsonStr = content.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.replaceAll(RegExp(r'```[a-z]*\n?'), '').trim();
    }
    
    // Remove trailing ``` if present
    if (jsonStr.endsWith('```')) {
      jsonStr = jsonStr.substring(0, jsonStr.length - 3).trim();
    }

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AiVerdict.fromJson({...json, 'provider': 'grok'});
  }

  // ─── Circuit breaker logic ─────────────────────────────────────────────────
  bool _isCircuitOpen(String provider) {
    final count = _failureCount[provider] ?? 0;
    if (count < _failureThreshold) return false;

    final openedAt = _circuitOpenedAt[provider];
    if (openedAt == null) return false;

    if (DateTime.now().difference(openedAt) > _circuitResetDuration) {
      // Reset circuit
      _failureCount[provider] = 0;
      _circuitOpenedAt[provider] = null;
      debugPrint('[LLM] Circuit reset for $provider');
      return false;
    }
    return true;
  }

  void _recordFailure(String provider) {
    _failureCount[provider] = (_failureCount[provider] ?? 0) + 1;
    if ((_failureCount[provider] ?? 0) >= _failureThreshold) {
      _circuitOpenedAt[provider] ??= DateTime.now();
      debugPrint('[LLM] Circuit OPENED for $provider');
    }
  }

  void _recordSuccess(String provider) {
    _failureCount[provider] = 0;
    _circuitOpenedAt[provider] = null;
  }
}

class _Provider {
  final String name;
  final Future<AiVerdict> Function(String text, String language) analyze;
  const _Provider({required this.name, required this.analyze});
}
