import 'dart:convert';
import 'dart:typed_data';
import 'package:basic_utils/basic_utils.dart';
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
  late int userId;

  // Setup variables
  setUpAll(() {
    var env = DotEnv(includePlatformEnvironment: true)..load(['.env.dev']);
    serverUrl = env['SERVER_URL'] ?? '';
    inviteCode = env['INVITE_CODE'] ?? '';
    publicKeyPem = File('publicKey.pem').readAsStringSync();
    privateKeyPem = File('privateKey.pem').readAsStringSync();
    userId = int.parse(env['USER_ID'] ?? '0');
  });

  // Create user on server
  test('register', () async {
    var apiClient = ApiClient(basePath: serverUrl);
    var authApi = AuthenticationApi(apiClient);
    // Create user
    var response = await authApi.createUser(
        createUserInput: CreateUserInput(
            inviteCode: inviteCode,
            publicKey: publicKeyPem,
            username: 'wsUnitTest'));
    // Check response
    if (response == null) {
      throw Exception('Failed to create user');
    } else {
      print('Write your user ID to .env.dev file: ${response.id}');
    }
  });

  // Get one time access token for WebSocket client
  Future<String> getOneTimeAccessToken() async {
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
    apiClient = ApiClient(basePath: serverUrl, authentication: auth);
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
          // TODO Decrypt message using my private key
          var messages = wsResponse.payload as List<PrivateMessage>;
          for (var message in messages) {
            print(
                'UserID: ${message.senderId} Message length: ${message.content.length}');
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
    // Connect to the server
    var wsClient = WsClient(getWsUrl(serverUrl), onReceived: (wsResponse) {
      // Print received message
      switch (wsResponse.type) {
        case WsResponseType.messages:
          // TODO Decrypt message using my private key
          var messages = wsResponse.payload as List<PrivateMessage>;
          for (var message in messages) {
            print(
                'UserID: ${message.senderId} Message length: ${message.content.length}');
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
    // TODO Encrypt the message using the public key of the user
    var messageToSendStr = 'Hello, World!';
    var key = Uint8List(32);
    var nonce = Uint8List(12);
    var mac = Uint8List(32);
    print('Sending message: $messageToSendStr');
    var messageToSend = WsMessage.privateMessage(
        NewPrivateMessage(userId, utf8.encode(messageToSendStr), key, nonce, mac));
    for (var i = 0; i < 5; i++) {
      var sentTime = wsClient.sendMessage(messageToSend);
      print('Message sent at: $sentTime');
      await Future.delayed(Duration(milliseconds: 500));
    }
    // Wait for 5 seconds
    await Future.delayed(Duration(seconds: 5));
    // Close WebSocket connection
    wsClient.disconnect();
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
        () => wsClient.sendMessage(WsMessage.privateMessage(
            NewPrivateMessage(userId, utf8.encode('Hello, World!'), Uint8List(32), Uint8List(12), Uint8List(32)))),
        throwsA(TypeMatcher<Exception>()));
  });
}