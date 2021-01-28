import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Encryption {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static encrypt.Key key;
  static encrypt.IV iv;

  Encryption() {
    _storage
        .read(key: "encryptKey")
        .then((value) => key = encrypt.Key.fromBase64(value));
    _storage.read(key: "IV").then((value) => iv = encrypt.IV.fromBase64(value));
  }

  static _encrypter() {
    return encrypt.Encrypter(encrypt.AES(key,padding: null));
  }

  static encryptText(String text)  {
    final encryptedText = _encrypter().encrypt(text, iv: iv);
    return encryptedText;
  }

  static decryptText(text)  {
    final decryptedText = _encrypter().decrypt(text, iv: iv);
    return decryptedText;
  }
}
