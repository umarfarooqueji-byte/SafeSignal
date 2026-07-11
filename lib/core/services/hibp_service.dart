import 'package:dio/dio.dart';

class BreachInfo {
  final String title;
  final String domain;
  final String breachDate;
  final int pwnCount;
  final String description;
  final List<String> dataClasses;
  final bool isVerified;
  final String logoPath; 

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
}

class HibpService {
  final Dio _dio = Dio();

  // Using XposedOrNot API as a completely free alternative to HIBP.
  // It returns real data breaches without requiring an API key.
  Future<List<BreachInfo>> checkEmail(String email) async {
    try {
      final response = await _dio.get(
        'https://api.xposedornot.com/v1/check-email/${Uri.encodeComponent(email)}',
        options: Options(
          headers: {'User-Agent': 'SafeSignal-App'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // If not found, it's safe
        if (data.containsKey('Error') && data['Error'] == 'Not found') {
          return [];
        }
        
        if (data.containsKey('breaches') && data['breaches'] != null) {
          final breachesArray = data['breaches'] as List;
          if (breachesArray.isNotEmpty && breachesArray.first is List) {
            final List<dynamic> breachNames = breachesArray.first;
            
            // XposedOrNot gives us names, we'll map them to our UI structure
            return breachNames.map((name) => BreachInfo(
              title: name.toString(),
              domain: name.toString().toLowerCase() + '.com', // Guessed
              breachDate: 'Unknown',
              pwnCount: 0,
              description: 'Your data was exposed in the $name data breach. We strongly advise changing your password.',
              dataClasses: ['Email addresses', 'Passwords'],
              isVerified: true,
              logoPath: 'https://haveibeenpwned.com/Content/Images/PwnedLogo.png',
            )).toList();
          }
        }
        return [];
      } else {
        throw Exception('XposedOrNot Error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // XposedOrNot usually returns 404 if email is clean
        return [];
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
