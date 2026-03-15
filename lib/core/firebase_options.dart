

class FirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: "AIzaSyB133olDzTvK3Zdlu7tRMXW9SfM5RPd7PU",
    authDomain: "lawhi-antigravity.firebaseapp.com",
    projectId: "lawhi-antigravity",
    storageBucket: "lawhi-antigravity.firebasestorage.app",
    messagingSenderId: "555731163427",
    appId: "1:555731163427:web:5c68d763eb35d7f3655496",
  );

  final String apiKey;
  final String authDomain;
  final String projectId;
  final String storageBucket;
  final String messagingSenderId;
  final String appId;

  const FirebaseOptions({
    required this.apiKey,
    required this.authDomain,
    required this.projectId,
    required this.storageBucket,
    required this.messagingSenderId,
    required this.appId,
  });

  // Simple mapping for initialization
  Map<String, String> toMap() => {
    'apiKey': apiKey,
    'authDomain': authDomain,
    'projectId': projectId,
    'storageBucket': storageBucket,
    'messagingSenderId': messagingSenderId,
    'appId': appId,
  };
}
