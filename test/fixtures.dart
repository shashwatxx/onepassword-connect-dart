import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:onepassword_connect/onepassword_connect.dart';

const vaultJson = {
  'id': 'ytrfte14kw1uex5txaore1emkz',
  'name': 'App Secrets',
  'attributeVersion': 1,
  'contentVersion': 9,
  'items': 2,
  'type': 'USER_CREATED',
  'createdAt': '2023-03-22T15:54:35Z',
  'updatedAt': '2023-03-22T15:55:19Z',
};

const itemSummaryJson = {
  'id': '2fcbqwe9ndg175zg2dzwftvkpa',
  'title': 'Postgres',
  'version': 3,
  'vault': {'id': 'ytrfte14kw1uex5txaore1emkz'},
  'category': 'DATABASE',
  'lastEditedBy': 'user-id',
  'createdAt': '2023-03-22T15:54:35Z',
  'updatedAt': '2023-03-22T15:55:19Z',
};

const fullItemJson = {
  ...itemSummaryJson,
  'sections': [
    {'id': 'section1', 'label': 'Credentials'},
  ],
  'fields': [
    {
      'id': 'username-field',
      'type': 'STRING',
      'purpose': 'USERNAME',
      'label': 'username',
      'value': 'admin',
    },
    {
      'id': 'password-field',
      'type': 'CONCEALED',
      'purpose': 'PASSWORD',
      'label': 'password',
      'value': 's3cr3t!',
      'entropy': 130.5,
    },
    {
      'id': 'otp-field',
      'type': 'OTP',
      'label': 'one-time password',
      'value': 'otpauth://totp/x?secret=abc',
      'totp': '123456',
      'section': {'id': 'section1'},
    },
    {
      'id': 'host-field',
      'type': 'STRING',
      'label': 'host',
      'value': 'db.internal',
      'section': {'id': 'section1'},
    },
  ],
  'files': [
    {
      'id': 'file1',
      'name': 'ca.pem',
      'size': 1024,
      'content_path':
          '/v1/vaults/ytrfte14kw1uex5txaore1emkz/items/2fcbqwe9ndg175zg2dzwftvkpa/files/file1/content',
    },
  ],
};

/// A recorded request captured by [clientWith].
class RecordedRequest {
  RecordedRequest(this.request, this.body);

  final http.Request request;
  final String body;

  String get method => request.method;
  Uri get url => request.url;
}

/// Builds an [OnePasswordConnect] whose transport is a [MockClient] answering
/// with [handler]. Requests are appended to [log] when provided.
OnePasswordConnect clientWith(
  http.Response Function(http.Request request) handler, {
  List<RecordedRequest>? log,
  String serverUrl = 'https://connect.example.com',
}) {
  return OnePasswordConnect(
    serverUrl: Uri.parse(serverUrl),
    token: 'test-token',
    httpClient: MockClient((request) async {
      log?.add(RecordedRequest(request, request.body));
      return handler(request);
    }),
  );
}

/// A 200 response with a JSON [body].
http.Response jsonResponse(Object body, {int status = 200}) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

/// A Connect-style error response.
http.Response errorResponse(int status, String message) =>
    jsonResponse({'status': status, 'message': message}, status: status);
