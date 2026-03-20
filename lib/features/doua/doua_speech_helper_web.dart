// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class DouaSpeechHelper {
  static void speakWeb(String text, {required Function() onEnd, required Function(String) onError}) {
    try {
      final synth = html.window.speechSynthesis;
      if (synth == null) return;
      
      synth.resume();
      synth.cancel();
      
      final voices = synth.getVoices();
      html.SpeechSynthesisVoice? selectedVoice;
      
      // Look for Google Arabic voices FIRST (highest quality on Chrome)
      for (var v in voices) {
        if (v.lang?.toLowerCase().startsWith('ar') ?? false) {
          if (v.name?.toLowerCase().contains('google') ?? false) {
            selectedVoice = v;
            break;
          }
        }
      }
      
      // Fallback to any Arabic voice if no Google voice
      if (selectedVoice == null) {
        for (var v in voices) {
          if (v.lang?.toLowerCase().startsWith('ar') ?? false) {
            selectedVoice = v;
            break;
          }
        }
      }
      
      if (selectedVoice == null) {
        onError("Aucune voix arabe trouvée.");
        return;
      }

      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.voice = selectedVoice;
      utterance.lang = selectedVoice.lang ?? 'ar-SA';
      utterance.rate = 0.85;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
      
      utterance.onEnd.listen((_) => onEnd());
      utterance.onError.listen((e) => onError("Erreur vocale web"));
      
      synth.speak(utterance);
    } catch (e) {
      onError(e.toString());
    }
  }

  static void stopWeb() {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
  }
}
