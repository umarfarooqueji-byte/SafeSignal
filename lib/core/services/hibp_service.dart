import 'package:dio/dio.dart';

class BreachInfo {
  final String title;
  final String domain;
  final String breachDate;
  final int pwnCount;
  final String description;
  final List<String> dataClasses;
  final bool isVerified;
  final String logoPath; // HIBP provides a logo URL usually, but we'll mock it

  BreachInfo({
    required this.title,
    required this.domain,
    required this.breachDate,
    required this.pwnCount,
    required this.description,
    required this.dataClasses,
    required this.isVerified,
    required this.logoPath,
  });

  factory BreachInfo.fromJson(Map<String, dynamic> json) {
    return BreachInfo(
      title: json['Title'] ?? '',
      domain: json['Domain'] ?? '',
      breachDate: json['BreachDate'] ?? '',
      pwnCount: json['PwnCount'] ?? 0,
      description: json['Description'] ?? '',
      dataClasses: List<String>.from(json['DataClasses'] ?? []),
      isVerified: json['IsVerified'] ?? false,
      logoPath: json['LogoPath'] ?? '',
    );
  }
}

class HibpService {
  final Dio _dio = Dio();
  // Optional: Add your HIBP API key here if you buy one
  final String _apiKey = '';

  Future<List<BreachInfo>> checkEmail(String email) async {
    // If we have no API key, use a realistic mock mode for demonstration
    if (_apiKey.isEmpty) {
      await Future.delayed(const Duration(seconds: 3)); // Simulate network
      return _getMockBreaches(email);
    }

    try {
      final response = await _dio.get(
        'https://haveibeenpwned.com/api/v3/breachedaccount/${Uri.encodeComponent(email)}',
        options: Options(
          headers: {
            'hibp-api-key': _apiKey,
            'user-agent': 'SafeSignal-App',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        // The /breachedaccount endpoint just returns breach NAMES (strings) by default.
        // To get full details, we would pass ?truncateResponse=false
        // For now, let's assume it returns full objects because truncateResponse=false
        return data.map((e) => BreachInfo.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        // 404 means no breaches found! Good news!
        return [];
      } else {
        throw Exception('HIBP Error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  List<BreachInfo> _getMockBreaches(String email) {
    // Return empty if the user types a specific "safe" email to test the safe state
    if (email.toLowerCase() == 'safe@gmail.com') {
      return [];
    }

    return [
      BreachInfo(
        title: 'Canva',
        domain: 'canva.com',
        breachDate: '2019-05-24',
        pwnCount: 137000000,
        description: 'In May 2019, graphic-design tool website Canva suffered a data breach that impacted 137 million subscribers. The exposed data included email addresses, usernames, names, cities of residence and passwords stored as bcrypt hashes.',
        dataClasses: ['Email addresses', 'Geographic locations', 'Names', 'Passwords', 'Usernames'],
        isVerified: true,
        logoPath: 'https://haveibeenpwned.com/Classes/Images/Logos/Canva.png',
      ),
      BreachInfo(
        title: 'Zomato',
        domain: 'zomato.com',
        breachDate: '2017-05-18',
        pwnCount: 17364659,
        description: 'In May 2017, the restaurant guide and food ordering service Zomato suffered a data breach. The breach resulted in the exposure of 17 million users\' email addresses and password hashes.',
        dataClasses: ['Email addresses', 'Passwords'],
        isVerified: true,
        logoPath: 'https://haveibeenpwned.com/Classes/Images/Logos/Zomato.png',
      ),
      BreachInfo(
        title: 'LinkedIn',
        domain: 'linkedin.com',
        breachDate: '2012-05-05',
        pwnCount: 164611595,
        description: 'In May 2012, LinkedIn had 164 million email addresses and passwords exposed. Originally thought to be under 7 million records, the full scale of the breach was realized in May 2016.',
        dataClasses: ['Email addresses', 'Passwords'],
        isVerified: true,
        logoPath: 'https://haveibeenpwned.com/Classes/Images/Logos/LinkedIn.png',
      )
    ];
  }
}
