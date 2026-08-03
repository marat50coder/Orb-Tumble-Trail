import 'dart:convert';

import '../config/orb_trail_config.dart';
import '../core/trail_models.dart';
import 'drift_agent.dart';
import 'orbit_attribution.dart';
import 'trail_store.dart';

class RelayExchange {
  RelayExchange(this._agent, this._store);

  final DriftAgent _agent;
  final TrailStore _store;

  Future<RelayReply> request(Map<String, dynamic> payload) async {
    if (!OrbTrailConfig.grayCredentialsReady) {
      return RelayReply.rejected('credentials_unavailable');
    }
    try {
      ottTrace(() => '[OTT.RELAY] request ${jsonEncode(payload)}');
      final response = await _agent
          .post(
            Uri.parse(OrbTrailConfig.endpoint),
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      ottTrace(
        () => '[OTT.RELAY] response ${response.statusCode} ${response.body}',
      );
      if (response.statusCode != 200) {
        return RelayReply.rejected('http_${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return RelayReply.rejected('invalid_response');
      final reply = RelayReply.fromJson(Map<String, dynamic>.from(decoded));
      if (reply.hasDestination) {
        await _store.cacheUrl(reply.url!, reply.expiresAt);
      }
      return reply;
    } catch (error) {
      ottTrace(() => '[OTT.RELAY] failed: $error');
      return RelayReply.rejected('network_failure');
    }
  }
}
