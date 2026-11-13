import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';
import 'package:test/test.dart';
import 'package:whisper_openapi_client_dart/api.dart';
import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:whisper_websocket_client_dart/models/new_private_message.dart';
import 'package:whisper_websocket_client_dart/models/private_message.dart';
import 'package:whisper_websocket_client_dart/models/ws_message.dart';
import 'package:whisper_websocket_client_dart/models/ws_response_type.dart';
import 'package:whisper_websocket_client_dart/ws_client.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as djwt;

void main() {
  late String serverUrl;
  late String inviteCode;
  late String publicKeyPem;
  late String privateKeyPem;
  late String userId;
  late RSAPublicKey publicKey;
  late RSAPrivateKey privateKey;

  // Setup variables
  setUpAll(() {
    var env = DotEnv(includePlatformEnvironment: true)..load(['.env.dev']);
    serverUrl = env['SERVER_URL'] ?? '';
    inviteCode = env['INVITE_CODE'] ?? '';
    publicKeyPem = File('publicKey.pem').readAsStringSync();
    privateKeyPem = File('privateKey.pem').readAsStringSync();
    userId = env['USER_ID'] ?? '';
    publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);
    privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
  });

  // Create user on server
  test('register', () async {
    var apiClient = ApiClient(basePath: serverUrl);
    var authApi = AuthenticationApi(apiClient);
    try {
      // Create user
      var response = await authApi.createUser(
          createUserInput: CreateUserInput(
              inviteCode: inviteCode,
              publicKey: publicKeyPem,
              username: 'wsUnitTest'));
      // Check response
      if (response == null) {
        throw Exception('Failed to create user');
      }
      print('Write your user ID to .env.dev file: ${response.id}');
    } on ApiException catch (e) {
      // The invite is single use: an already registered account is fine
      if (userId.isEmpty) {
        rethrow;
      }
      print('Account already registered as USER_ID=$userId (${e.message})');
    }
  });

  // Get an authenticated API client (RSA JWT -> access token)
  Future<ApiClient> getAuthenticatedApiClient() async {
    var apiClient = ApiClient(basePath: serverUrl);
    var authApi = AuthenticationApi(apiClient);
    // Generate JWT
    final jwt = djwt.JWT({'sub': userId});
    Duration expiresIn = Duration(seconds: 5);
    Duration notBefore = Duration.zero;
    final token = jwt.sign(
        djwt.RSAPrivateKey.raw(CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem)),
        algorithm: djwt.JWTAlgorithm.RS256,
        expiresIn: expiresIn,
        notBefore: notBefore,
        noIssueAt: false);
    // Auth user
    var authResponse =
        await authApi.authUser(authUserInput: AuthUserInput(token: token));
    if (authResponse == null) {
      throw Exception('Failed to authenticate user');
    }
    // Set access token
    var auth = HttpBearerAuth();
    auth.accessToken = authResponse.accessToken;
    return ApiClient(basePath: serverUrl, authentication: auth);
  }

  // Get one time access token for WebSocket client
  Future<String> getOneTimeAccessToken() async {
    var apiClient = await getAuthenticatedApiClient();
    // Get one time access token
    var wsAuthApi = WebSocketAuthenticationApi(apiClient);
    var wsAuthResponse = await wsAuthApi.webSocketAuth();
    if (wsAuthResponse == null) {
      throw Exception('Failed to get one time access token');
    }
    return wsAuthResponse.accessToken;
  }

  // Get WebSocket URL
  String getWsUrl(String serverUrl) {
    String wsUrl = serverUrl.contains('https')
        ? serverUrl.replaceFirst('https', 'wss')
        : serverUrl.replaceFirst('http', 'ws');
    return '$wsUrl/ws';
  }

  // Test getting one time access token
  test('getOneTimeAccessToken', () async {
    var accessToken = await getOneTimeAccessToken();
    print('One time access token: $accessToken');
  });

  // Test connecting to the server
  test('connectToServer', () async {
    // Get access token
    var accessToken = await getOneTimeAccessToken();
    // Connect to the server
    var wsClient = WsClient(getWsUrl(serverUrl), onReceived: (wsResponse) {
      // Print received message
      switch (wsResponse.type) {
        case WsResponseType.messages:
          var messages = wsResponse.payload as List<PrivateMessage>;
          for (var message in messages) {
            try {
              var content = decryptMessage(message.content, message.key,
                  message.nonce, message.mac, privateKey);
              print('UserID: ${message.senderId} Message: $content');
            } catch (e) {
              print('Failed to decrypt message from ${message.senderId}: $e');
            }
          }
          break;
        case WsResponseType.error:
          var error = wsResponse.payload as String;
          print('Received error: $error');
          break;
        default:
          print('Response type: ${wsResponse.type}');
          break;
      }
    });
    await wsClient.connect(accessToken, Duration(seconds: 5));
    // Wait for 60 seconds
    await Future.delayed(Duration(seconds: 60));
    // Close WebSocket connection
    wsClient.disconnect();
  }, timeout: Timeout(Duration(seconds: 70)));

  // Test connecting to the server and sending message to self
  // NOTE: Sending message to self won't work in production.
  test('connectAndSendMessageToSelf', () async {
    // Get access token
    var accessToken = await getOneTimeAccessToken();
    // Decrypted messages received from the server
    var decryptedMessages = <String>[];
    // Connect to the server
    var wsClient = WsClient(getWsUrl(serverUrl), onReceived: (wsResponse) {
      // Print received message
      switch (wsResponse.type) {
        case WsResponseType.messages:
          var messages = wsResponse.payload as List<PrivateMessage>;
          for (var message in messages) {
            try {
              var content = decryptMessage(message.content, message.key,
                  message.nonce, message.mac, privateKey);
              decryptedMessages.add(content);
              print('UserID: ${message.senderId} Message: $content');
            } catch (e) {
              print('Failed to decrypt message from ${message.senderId}: $e');
            }
          }
          break;
        case WsResponseType.error:
          var error = wsResponse.payload as String;
          print('Received error: $error');
          break;
        default:
          print('Response type: ${wsResponse.type}');
          break;
      }
    });
    await wsClient.connect(accessToken, Duration(seconds: 5));
    // Send message
    var messageToSendStr = 'Hello, World!';
    // Self chat, so the recipient key is our own public key
    var encrypted = encryptMessage(messageToSendStr, publicKey);
    print('Sending message: $messageToSendStr');
    var messageToSend = WsMessage.privateMessage(NewPrivateMessage(
        userId,
        encrypted['encryptedData']!,
        encrypted['encryptedKey']!,
        encrypted['nonce']!,
        encrypted['mac']!));
    for (var i = 0; i < 5; i++) {
      var sentTime = wsClient.sendMessage(messageToSend);
      print('Message sent at: $sentTime');
      await Future.delayed(Duration(milliseconds: 500));
    }
    // Wait for 5 seconds
    await Future.delayed(Duration(seconds: 5));
    // Close WebSocket connection
    wsClient.disconnect();
    // The messages must come back and decrypt to what was sent
    expect(decryptedMessages, isNotEmpty);
    expect(decryptedMessages, everyElement(messageToSendStr));
  });

  // Send an encrypted message to the admin account
  test('sendMessageToAdmin', () async {
    var apiClient = await getAuthenticatedApiClient();
    // Find admin among the searched users
    var users = await UserApi(apiClient).searchUsers('admin');
    var admins = users?.where((u) => u.admin).toList() ?? [];
    if (admins.isEmpty) {
      throw Exception('Admin user not found');
    }
    var admin = admins.first;
    // Encrypt with the admin public key
    var messageToSendStr =
        'Hello admin, this is a test message from the WebSocket client.';
    var encrypted = encryptMessage(
        messageToSendStr, CryptoUtils.rsaPublicKeyFromPem(admin.publicKey));
    var wsAuthResponse =
        await WebSocketAuthenticationApi(apiClient).webSocketAuth();
    if (wsAuthResponse == null) {
      throw Exception('Failed to get one time access token');
    }
    // Connect to the server
    var wsClient = WsClient(getWsUrl(serverUrl));
    await wsClient.connect(wsAuthResponse.accessToken, Duration(seconds: 5));
    print('Sending message to admin (id ${admin.id}): $messageToSendStr');
    var sentTime = wsClient.sendMessage(WsMessage.privateMessage(
        NewPrivateMessage(
            admin.id,
            encrypted['encryptedData']!,
            encrypted['encryptedKey']!,
            encrypted['nonce']!,
            encrypted['mac']!)));
    print('Message sent at: $sentTime');
    await Future.delayed(Duration(seconds: 2));
    wsClient.disconnect();
  });

  // Encrypt/decrypt round trip without a server
  test('encryptAndDecryptRoundTrip', () {
    var encrypted = encryptMessage('Hello, World!', publicKey);
    var decrypted = decryptMessage(
        encrypted['encryptedData']!,
        encrypted['encryptedKey']!,
        encrypted['nonce']!,
        encrypted['mac']!,
        privateKey);
    expect(decrypted, 'Hello, World!');
  });

  // Test isConnected getter
  test('isConnected', () {
    var wsClient = WsClient(getWsUrl(serverUrl));
    expect(wsClient.isConnected, false);
  });

  // Test sending message when not connected
  test('sendMessageWhenNotConnected', () {
    var wsClient = WsClient(getWsUrl(serverUrl));
    expect(
        () => wsClient.sendMessage(WsMessage.privateMessage(NewPrivateMessage(
            userId,
            utf8.encode('Hello, World!'),
            Uint8List(32),
            Uint8List(12),
            Uint8List(32)))),
        throwsA(TypeMatcher<Exception>()));
  });
}

/// Encrypts [plaintext] for the holder of [publicKey].
///
/// Same layout as the app: a random AES-256-GCM key encrypts the content, and
/// the RSA-encrypted AES key travels next to it.
Map<String, Uint8List> encryptMessage(
    String plaintext, RSAPublicKey publicKey) {
  final random = Random.secure();
  final aesKey =
      Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
  final nonce =
      Uint8List.fromList(List.generate(12, (_) => random.nextInt(256)));

  final aesCipher = GCMBlockCipher(AESEngine())
    ..init(
        true, AEADParameters(KeyParameter(aesKey), 128, nonce, Uint8List(0)));
  // GCM appends the 16-byte tag to the ciphertext; the protocol carries them apart
  final sealed = aesCipher.process(Uint8List.fromList(utf8.encode(plaintext)));
  final cipherTextLength = sealed.length - 16;

  final rsaCipher = PKCS1Encoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

  return {
    'encryptedData': sealed.sublist(0, cipherTextLength),
    'encryptedKey': rsaCipher.process(aesKey),
    'nonce': nonce,
    'mac': sealed.sublist(cipherTextLength),
  };
}

/// Decrypts a received message with the recipient's [privateKey].
String decryptMessage(Uint8List content, Uint8List key, Uint8List nonce,
    Uint8List mac, RSAPrivateKey privateKey) {
  final rsaCipher = PKCS1Encoding(RSAEngine())
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
  final aesKey = rsaCipher.process(key);

  final aesCipher = GCMBlockCipher(AESEngine())
    ..init(
        false, AEADParameters(KeyParameter(aesKey), 128, nonce, Uint8List(0)));
  final plain = aesCipher.process(Uint8List.fromList([...content, ...mac]));
  return utf8.decode(plain);
}
