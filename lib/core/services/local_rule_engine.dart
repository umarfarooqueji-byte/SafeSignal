import 'package:flutter/foundation.dart';
import '../models/ai_verdict.dart';

/// Pure Dart offline rule engine — no network, always works.
/// Runs as Tier 1 before any cloud LLM call.
class LocalRuleEngine {
  // ─── Scam keyword banks ────────────────────────────────────────────────────
  static const _urgencyKeywords = [
    'kyc block', 'kyc update', 'kyc expired', 'kyc verify',
    'account suspend', 'account blocked', 'account closed', 'account deactivated',
    'aadhaar link', 'pan link', 'pan update',
    'otp share', 'otp bata', 'otp send',
    'arrest', 'police', 'cbi', 'cybercrime', 'digital arrest',
    'lottery', 'won prize', 'congratulation', 'lucky winner',
    'free recharge', 'free gift', 'click here', 'claim now',
    'urgent', 'immediately', 'last chance', 'expire today',
    'emi pending', 'loan approve', 'job offer', 'work from home',
    '100% return', 'double your', 'invest now', 'guaranteed profit',
    'anydesk', 'teamviewer', 'screen share', 'remote access',
  ];

  static const _safeKeywords = [
    'otp is', 'your otp', 'transaction otp', 'login otp',
    'hdfc bank', 'sbi bank', 'icici bank', 'axis bank', 'kotak bank',
    'neft', 'imps', 'upi payment', 'paytm', 'phonepay', 'gpay',
  ];

  static const _suspiciousDomainPatterns = [
    'bit.ly', 'tinyurl', 'goo.gl', 't.co', 'ow.ly', 'shorturl',
    '-secure', '-verify', '-update', '-login', '-bank', '-kyc',
    'sbi-', 'hdfc-', 'icici-', 'paytm-',
  ];

  // International number pattern (checked inline)
  static final _intlSenderPattern = RegExp(r'^\+[^9][0-9]');

  // ─── Main analyze function ─────────────────────────────────────────────────
  AiVerdict analyze(String text, {String? sender, String? type}) {
    final lower = text.toLowerCase();
    final reasons = <String>[];
    var riskScore = 0;

    // 1. Urgency / scare keywords
    final foundUrgency = _urgencyKeywords.where((kw) => lower.contains(kw)).toList();
    if (foundUrgency.isNotEmpty) {
      riskScore += foundUrgency.length * 12;
      reasons.add('Urgent/threatening language detected: "${foundUrgency.first}"');
    }

    // 2. Shortened / suspicious URLs
    final foundDomains = _suspiciousDomainPatterns.where((p) => lower.contains(p)).toList();
    if (foundDomains.isNotEmpty) {
      riskScore += 20;
      reasons.add('Suspicious link pattern found: "${foundDomains.first}" — may redirect to phishing page');
    }

    // 3. URL present at all
    final hasUrl = RegExp(r'https?://|www\.|\.(com|in|net|org)').hasMatch(lower);
    if (hasUrl && foundDomains.isEmpty) {
      riskScore += 8;
      reasons.add('Contains a web link — verify before clicking');
    }

    // 4. OTP request pattern (not legitimate OTP delivery)
    final otpRequest = RegExp(r'(share|bata|send|de do|forward).{0,20}otp').hasMatch(lower);
    if (otpRequest) {
      riskScore += 35;
      reasons.add('Asking you to SHARE your OTP — no legitimate bank/service ever asks for this');
    }

    // 5. Money/prize promises
    final moneyPromise = RegExp(r'(₹|rs\.?|inr|lakh|crore|prize|lottery|won|reward)').hasMatch(lower);
    if (moneyPromise) {
      riskScore += 15;
      reasons.add('Mentions money/prize — common scam tactic to create greed');
    }

    // 6. Call forwarding attack (*21*)
    if (lower.contains('*21*') || lower.contains('**21') || lower.contains('divert')) {
      riskScore += 50;
      reasons.add('Contains *21* call forwarding code — this is a call hijacking scam!');
    }

    // 7. Remote access tools
    if (lower.contains('anydesk') || lower.contains('teamviewer') || lower.contains('quick support')) {
      riskScore += 45;
      reasons.add('Mentions remote access app (AnyDesk/TeamViewer) — scammer wants to take over your phone');
    }

    // 8. Safe signal — legitimate OTP delivery
    final foundSafe = _safeKeywords.where((kw) => lower.contains(kw)).toList();
    if (foundSafe.isNotEmpty && riskScore < 20) {
      riskScore = (riskScore * 0.3).round();
      reasons.add('Pattern matches legitimate OTP/transaction message');
    }

    // 9. Suspicious sender (international number masquerading)
    if (sender != null) {
      if (_intlSenderPattern.hasMatch(sender)) {
        riskScore += 15;
        reasons.add('Sent from an international number ($sender) — Indian banks only use 6-digit sender IDs');
      }
    }

    // Cap score at 100
    riskScore = riskScore.clamp(0, 100);

    // Determine verdict
    String verdict;
    if (riskScore >= 60) {
      verdict = 'SCAM';
    } else if (riskScore >= 30) {
      verdict = 'SUSPICIOUS';
    } else {
      verdict = 'SAFE';
    }

    if (reasons.isEmpty) {
      reasons.add(verdict == 'SAFE'
          ? 'No suspicious patterns detected'
          : 'Low-confidence suspicious signal detected');
    }

    final whatToDo = _buildWhatToDo(verdict, riskScore);

    debugPrint('[RuleEngine] verdict=$verdict score=$riskScore reasons=${reasons.length}');

    return AiVerdict(
      verdict: verdict,
      riskScore: riskScore,
      reasons: reasons,
      whatToDo: whatToDo,
      summary: _buildSummary(verdict, riskScore),
      confidence: riskScore > 60 ? 0.85 : (riskScore > 30 ? 0.65 : 0.80),
      provider: 'rule_engine',
      isOffline: true,
    );
  }

  List<String> _buildWhatToDo(String verdict, int score) {
    if (verdict == 'SCAM') {
      return [
        'Do NOT click any links or share any OTP',
        'Block and report this sender immediately',
        'Call Cyber Helpline 1930 if you already shared OTP or money',
        'Forward this message to 7726 (spam reporting)',
      ];
    } else if (verdict == 'SUSPICIOUS') {
      return [
        'Be very cautious — verify the sender through official channels',
        'Never share OTP, password, or Aadhaar number',
        'Call the official number of your bank/company to verify',
      ];
    }
    return ['This message looks legitimate, but always stay alert'];
  }

  String _buildSummary(String verdict, int score) {
    if (verdict == 'SCAM') {
      return 'High risk — this message shows $score/100 risk score with multiple scam indicators. Do NOT respond or click any links.';
    } else if (verdict == 'SUSPICIOUS') {
      return 'Moderate risk ($score/100) — some suspicious patterns found. Verify before taking any action.';
    }
    return 'This message appears safe ($score/100 risk score) — no major red flags detected.';
  }
}
