import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/batch.dart';
import '../models/vocab.dart';
import '../models/vocab_set.dart';

class ApiService {
  final String baseUrl =
      "https://danish-vocab-v6ojsf2tea-ma.a.run.app"; // Replace with real backend URL

  Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Vocab>> fetchAllVocab() async {
    final response = await http.get(
      Uri.parse("$baseUrl/vocab"),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Vocab.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch vocabulary");
    }
  }

  Future<Vocab> addVocab(Vocab vocab) async {
    final response = await http.post(
      Uri.parse("$baseUrl/vocab"),
      headers: await _authHeaders(),
      body: json.encode(vocab.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return Vocab.fromJson(jsonBody);
    } else {
      throw Exception("Failed to add vocabulary");
    }
  }

  Future<Vocab> updateVocab(Vocab vocab) async {
    final response = await http.put(
      Uri.parse("$baseUrl/vocab"),
      headers: await _authHeaders(),
      body: json.encode(vocab.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return Vocab.fromJson(jsonBody);
    } else {
      throw Exception("Failed to update vocabulary");
    }
  }

  Future<void> deleteVocab(String id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/vocab/$id"),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete vocabulary");
    }
  }

  Future<Batch> fetchBatch() async {
    final response = await http.get(
      Uri.parse("$baseUrl/classroom/batch"),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Batch.fromJson(data);
    } else {
      throw Exception("Failed to fetch batch");
    }
  }

  Future<void> removeBatchItems(List<Vocab> vocabs) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/classroom/batch"),
      headers: await _authHeaders(),
      body: json.encode(vocabs.map((v) => v.toJson()).toList()),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to remove vocab from batch");
    }
  }

  /// ✅ Remove vocab from batch (POST /classroom/batch)
  Future<void> submitBatchResult(
    List<Vocab> withoutMistakes,
    List<Vocab> withMistakes,
  ) async {
    final body = {
      "without_mistake": withoutMistakes.map((v) => v.toJson()).toList(),
      "with_mistake": withMistakes.map((v) => v.toJson()).toList(),
    };

    final response = await http.post(
      Uri.parse("$baseUrl/classroom/batch"),
      headers: await _authHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to remove vocab from batch");
    }
  }

  /// Fetches all vocab sets for the authenticated user
  Future<List<VocabSet>> fetchVocabSets() async {
    final response = await http.get(
      Uri.parse("$baseUrl/classroom/sets"),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => VocabSet.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch vocab sets");
    }
  }

  /// Creates a new vocab set for the authenticated user
  Future<VocabSet> createVocabSet(String name, List<String> vocabIds) async {
    final body = {
      "name": name,
      "vocab_ids": vocabIds,
    };

    final response = await http.post(
      Uri.parse("$baseUrl/classroom/sets"),
      headers: await _authHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonBody = json.decode(response.body);
      return VocabSet.fromJson(jsonBody);
    } else {
      throw Exception("Failed to create vocab set");
    }
  }

  /// Updates an existing vocab set for the authenticated user
  Future<void> updateVocabSet(String setId, String name, List<String> vocabIds) async {
    final body = {
      "name": name,
      "vocab_ids": vocabIds,
    };

    final response = await http.put(
      Uri.parse("$baseUrl/classroom/sets/$setId"),
      headers: await _authHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update vocab set");
    }
  }

  /// Fetches a batch of vocabulary items from a specific vocab set
  Future<Batch> fetchBatchFromSet(String setId, {int? limit}) async {
    final queryParams = <String, String>{};
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }

    final uri = Uri.parse("$baseUrl/classroom/sets/$setId/batch")
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    final response = await http.get(
      uri,
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Batch.fromJson(data);
    } else {
      throw Exception("Failed to fetch batch from set");
    }
  }

  /// Deletes a vocab set for the authenticated user
  Future<void> deleteVocabSet(String setId) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/classroom/sets/$setId"),
      headers: await _authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete vocab set");
    }
  }
}
