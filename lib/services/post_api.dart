import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/destination.dart';
import '../models/paginated.dart';
import '../models/post.dart';
import 'api_client.dart';

/// Profil user + postingannya (GET /api/users/{id}).
class UserProfile {
  final int id;
  final String name;
  final String? bio;
  final String? photo;
  final List<PostCard> posts;

  const UserProfile({
    required this.id,
    required this.name,
    this.bio,
    this.photo,
    required this.posts,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final postsRaw = json['posts'] as List? ?? [];
    return UserProfile(
      id: json['id'] as int,
      name: (json['name'] ?? 'Unknown') as String,
      bio: json['bio'] as String?,
      photo: json['photo'] as String?,
      posts: postsRaw
          .whereType<Map>()
          .map((e) => PostCard.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

/// Endpoint postingan (feed, detail, buat, hapus, rating, profil user).
class PostApi {
  final ApiClient _client;

  PostApi(this._client);

  Future<Paginated<PostCard>> feed({int page = 1}) async {
    final json = await _client.get('/posts', query: {
      'page': page,
      'per_page': AppConfig.feedPerPage,
    });
    return Paginated.fromJson(
      Map<String, dynamic>.from(json as Map),
      PostCard.fromJson,
    );
  }

  Future<PostDetail> detail(int id) async {
    final json = await _client.get('/posts/$id');
    return PostDetail.fromJson(Map<String, dynamic>.from(json['data'] as Map));
  }

  Future<PostDetail> create({
    required String title,
    String? location,
    String? story,
    int totalBudget = 0,
    String? travelDate,
    List<Destination> destinations = const [],
    List<String> photoPaths = const [],
  }) async {
    final fields = <String, String>{
      'title': title,
      if (location != null && location.isNotEmpty) 'location': location,
      if (story != null && story.isNotEmpty) 'story': story,
      'total_budget': '$totalBudget',
      if (travelDate != null && travelDate.isNotEmpty) 'travel_date': travelDate,
      // Backend menerima string JSON: json_decode($request->destinations).
      'destinations': jsonEncode(destinations.map((d) => d.toJson()).toList()),
    };

    final json = await _client.multipart(
      '/posts',
      fields: fields,
      filePaths: photoPaths,
    );
    return PostDetail.fromJson(Map<String, dynamic>.from(json['data'] as Map));
  }

  // Tambahkan fungsi ini di DALAM class PostApi
  Future<PostDetail> update({
    required int id,
    required String title,
    String? location,
    String? story,
    int totalBudget = 0,
    String? travelDate,
    List<Destination> destinations = const [],
    List<String> newPhotoPaths = const [],
  }) async {
    final fields = <String, String>{
      'title': title,
      if (location != null && location.isNotEmpty) 'location': location,
      if (story != null && story.isNotEmpty) 'story': story,
      'total_budget': '$totalBudget',
      if (travelDate != null && travelDate.isNotEmpty) 'travel_date': travelDate,
      'destinations': jsonEncode(destinations.map((d) => d.toJson()).toList()),
      // Tambahkan ini untuk berjaga-jaga jika server butuh penanda
      '_method': 'POST', 
    };

    try {
      final json = await _client.multipart(
        '/posts/$id/update', 
        fields: fields,
        filePaths: newPhotoPaths,
      );
      return PostDetail.fromJson(Map<String, dynamic>.from(json['data'] as Map));
    } catch (e) {
      // Tambahkan print ini di terminal VS Code untuk melihat detail error sebenarnya
      debugPrint('Error saat update post: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    await _client.delete('/posts/$id');
  }

  Future<void> rate(int id, int score) async {
    await _client.post('/posts/$id/rate', body: {'score': score});
  }

  Future<UserProfile> userProfile(int id) async {
    final json = await _client.get('/users/$id');
    return UserProfile.fromJson(Map<String, dynamic>.from(json['data'] as Map));
  }
}
