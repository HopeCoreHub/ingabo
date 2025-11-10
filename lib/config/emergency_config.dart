import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

class EmergencyConfig {
  // Emergency numbers by region (default: Rwanda)
  static Map<String, EmergencyNumbers> getEmergencyNumbers(String locale) {
    switch (locale) {
      case 'French':
        return {
          'rwanda': EmergencyNumbers(
            police: '112',
            isangeCenter: '3029',
            rib: '3512',
            hopeCore: '+250780332779',
          ),
        };
      case 'Swahili':
        return {
          'rwanda': EmergencyNumbers(
            police: '112',
            isangeCenter: '3029',
            rib: '3512',
            hopeCore: '+250780332779',
          ),
        };
      case 'Kinyarwanda':
        return {
          'rwanda': EmergencyNumbers(
            police: '112',
            isangeCenter: '3029',
            rib: '3512',
            hopeCore: '+250780332779',
          ),
        };
      default: // English
        return {
          'rwanda': EmergencyNumbers(
            police: '112',
            isangeCenter: '3029',
            rib: '3512',
            hopeCore: '+250780332779',
          ),
        };
    }
  }

  // Get localized emergency service names
  static Map<String, String> getEmergencyServiceNames(BuildContext context) {
    return {
      'police': AppLocalizations.of(context).translate('policeEmergency'),
      'isangeCenter': AppLocalizations.of(context).translate('isangeOneStopCenter'),
      'rib': AppLocalizations.of(context).translate('rwandaInvestigationBureau'),
      'hopeCore': AppLocalizations.of(context).translate('hopeCoreHubTeam'),
    };
  }

  // Get localized emergency messages
  static String getEmergencySmsMessage(BuildContext context) {
    return AppLocalizations.of(context).translate('helloINeedHelpRegardingSafetyConcern');
  }

  // Format phone number for platform
  static String formatPhoneNumber(String number, {bool isInternational = false}) {
    // Remove any non-digit characters except +
    String cleaned = number.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Add country code if needed for international format
    if (isInternational && !cleaned.startsWith('+')) {
      // Default to Rwanda country code
      if (cleaned.length <= 9) {
        cleaned = '+250$cleaned';
      }
    }
    
    return cleaned;
  }
}

class EmergencyNumbers {
  final String police;
  final String isangeCenter;
  final String rib;
  final String hopeCore;

  EmergencyNumbers({
    required this.police,
    required this.isangeCenter,
    required this.rib,
    required this.hopeCore,
  });
}

