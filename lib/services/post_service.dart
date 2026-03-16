// lib/services/post_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import 'api_exception.dart';

class PostService {
  static const String _baseUrl =
      'https://jsonplaceholder.typicode.com/posts';

  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'application/json',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  static const Duration _timeout = Duration(seconds: 15);

  /// Fetches all posts from the API.
  /// Returns a [List<Post>].
  /// Throws [NetworkException], [ServerException], or [ParseException].
  Future<List<Post>> fetchAllPosts() async {
    try {
      final response = await http
          .get(Uri.parse(_baseUrl), headers: _headers)
          .timeout(_timeout);

      _checkStatus(response);

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      return jsonList
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
          'No internet connection. Please check your network.');
    } on HttpException {
      throw const NetworkException('Could not reach the server.');
    } on FormatException catch (e) {
      throw ParseException('Invalid data format: ${e.message}');
    } catch (e) {
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // GET single post by id
  // ---------------------------------------------------------------------------

  /// Fetches a single post by [id].
  /// Throws [NotFoundException] if the post does not exist.
  Future<Post> fetchPost(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/$id'), headers: _headers)
          .timeout(_timeout);

      _checkStatus(response);

      return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
          'No internet connection. Please check your network.');
    } on FormatException catch (e) {
      throw ParseException('Invalid data format: ${e.message}');
    } catch (e) {
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // POST — Create a new post
  // ---------------------------------------------------------------------------

  /// Creates a new post on the server.
  /// JSONPlaceholder simulates creation and returns the new post with an id.
  Future<Post> createPost({
    required int userId,
    required String title,
    required String body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'userId': userId,
              'title': title,
              'body': body,
            }),
          )
          .timeout(_timeout);

      _checkStatus(response);

      return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
          'No internet connection. Please check your network.');
    } on FormatException catch (e) {
      throw ParseException('Invalid data format: ${e.message}');
    } catch (e) {
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // PUT — Update an existing post
  // ---------------------------------------------------------------------------

  /// Fully replaces the post with the given [post].
  Future<Post> updatePost(Post post) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/${post.id}'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(post.toJson()),
          )
          .timeout(_timeout);

      _checkStatus(response);

      return Post.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
          'No internet connection. Please check your network.');
    } on FormatException catch (e) {
      throw ParseException('Invalid data format: ${e.message}');
    } catch (e) {
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE — Remove a post
  // ---------------------------------------------------------------------------

  /// Deletes the post with the given [id].
  /// JSONPlaceholder returns 200 with an empty body on success.
  Future<void> deletePost(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/$id'))
          .timeout(_timeout);

      _checkStatus(response);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException(
          'No internet connection. Please check your network.');
    } catch (e) {
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Inspects the HTTP [response] status code and throws the appropriate
  /// [ApiException] subclass when the request was not successful.
  void _checkStatus(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) return;

    if (code == 404) {
      throw const NotFoundException('The requested resource was not found.');
    } else if (code >= 400 && code < 500) {
      throw ServerException(
        'Client error: ${response.reasonPhrase}',
        statusCode: code,
      );
    } else if (code >= 500) {
      throw ServerException(
        'Server error: ${response.reasonPhrase}',
        statusCode: code,
      );
    } else {
      throw ServerException(
        'Unexpected response: ${response.reasonPhrase}',
        statusCode: code,
      );
    }
  }
}
