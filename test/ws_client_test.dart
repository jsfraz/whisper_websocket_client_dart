import 'dart:convert';
import 'dart:math';
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

void main() {
  late String serverUrl;
  late String inviteCode;
  late String publicKeyPem;
  late String privateKeyPem;
  late int userId;

  // Setup variables
  setUpAll(() {
    var env = DotEnv(includePlatformEnvironment: true)
      ..load(['.env.development']);
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
      print('Write your user ID to .env.development file: ${response.id}');
    }
  });

  // Get one time access token for WebSocket client
  Future<String> getOneTimeAccessToken() async {
    var apiClient = ApiClient(basePath: serverUrl);
    var authApi = AuthenticationApi(apiClient);
    // Generate and sign nonce
    var nonce = Uint8List.fromList(
        List.generate(256, (_) => Random.secure().nextInt(256)));
    final signer = Signer('SHA-256/RSA');
    final rsaPrivateKeyParams = PrivateKeyParameter<RSAPrivateKey>(
        CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem));
    signer.init(true, rsaPrivateKeyParams);
    final signedNonce = signer.generateSignature(nonce) as RSASignature;
    // Auth user
    var authResponse = await authApi.authUser(
        authUserInput: AuthUserInput(
            nonce: base64Encode(nonce),
            signedNonce: base64Encode(signedNonce.bytes),
            userId: userId));
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
    var wsClient = WsClient(getWsUrl(serverUrl), (_) {});
    wsClient.connect(accessToken);
    // Wait for 5 seconds
    await Future.delayed(Duration(seconds: 5));
    // Close WebSocket connection
    wsClient.disconnect();
  });

  // Test connecting to the server and sending message to self
  // NOTE: Sending message to self wont work, I am doing this while debuging the server.
  test('connectAndSendMessageToSelf', () async {
    // Get access token
    var accessToken = await getOneTimeAccessToken();
    // Connect to the server
    var wsClient = WsClient(getWsUrl(serverUrl), (wsResponse) {
      // Print received message
      switch (wsResponse.type) {
        case WsResponseType.message:
          var message = wsResponse.payload as PrivateMessage;
          print('Received message: ${utf8.decode(message.message)}');
          break;
        case WsResponseType.error:
          var error = wsResponse.payload as String;
          print('Received error: $error');
          break;
      }
    });
    wsClient.connect(accessToken);
    // Send message
    // TODO actually encrypt the message using the public key of the user
    var messageToSendStr = 'Hello, World!';
    print('Sending message: $messageToSendStr');
    var messageToSend = WsMessage.privateMessage(
        NewPrivateMessage(userId, utf8.encode(messageToSendStr), DateTime.now()));
    wsClient.sendMessage(messageToSend);
    // Wait for 5 seconds
    await Future.delayed(Duration(seconds: 5));
    // Close WebSocket connection
    wsClient.disconnect();
  });

  // Test isConnected getter
  test('isConnected', () {
    var wsClient = WsClient(getWsUrl(serverUrl), (_) {});
    expect(wsClient.isConnected, false);
  });
}
