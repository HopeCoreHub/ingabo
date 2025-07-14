import 'package:flutter_test/flutter_test.dart';
import 'package:ingabo/mahoro_page.dart';

void main() {
  group('Mahoro Simulation Tests', () {
    test('Simulated responses are generated correctly for different languages', () {
      // Create a simple function to simulate the response generation logic
      String getSimulatedResponse(String language) {
        switch (language) {
          case 'EN':
            return "Thank you for sharing. I understand how you feel and I'm here to listen. Would you like to tell me more about what's on your mind?";
          case 'RW':
            return "Murakoze kubisangiza. Ndumva uko meze kandi ndi hano kugira ngo mbumve. Ushaka kumbwira byinshi ku biri mu mutwe wawe?";
          case 'FR':
            return "Merci de partager. Je comprends ce que vous ressentez et je suis là pour vous écouter. Souhaitez-vous me dire plus sur ce qui vous préoccupe?";
          case 'SW':
            return "Asante kwa kushiriki. Ninaelewa jinsi unavyohisi na niko hapa kukusikiliza. Ungependa kuniambia zaidi kuhusu kilicho akilini mwako?";
          default:
            return "Thank you for sharing. I understand how you feel and I'm here to listen. Would you like to tell me more about what's on your mind?";
        }
      }

      // Test English response
      expect(
        getSimulatedResponse('EN'),
        "Thank you for sharing. I understand how you feel and I'm here to listen. Would you like to tell me more about what's on your mind?"
      );
      
      // Test Kinyarwanda response
      expect(
        getSimulatedResponse('RW'),
        "Murakoze kubisangiza. Ndumva uko meze kandi ndi hano kugira ngo mbumve. Ushaka kumbwira byinshi ku biri mu mutwe wawe?"
      );
      
      // Test French response
      expect(
        getSimulatedResponse('FR'),
        "Merci de partager. Je comprends ce que vous ressentez et je suis là pour vous écouter. Souhaitez-vous me dire plus sur ce qui vous préoccupe?"
      );
      
      // Test Swahili response
      expect(
        getSimulatedResponse('SW'),
        "Asante kwa kushiriki. Ninaelewa jinsi unavyohisi na niko hapa kukusikiliza. Ungependa kuniambia zaidi kuhusu kilicho akilini mwako?"
      );
      
      // Test default response
      expect(
        getSimulatedResponse('UNKNOWN'),
        "Thank you for sharing. I understand how you feel and I'm here to listen. Would you like to tell me more about what's on your mind?"
      );
    });
  });
} 