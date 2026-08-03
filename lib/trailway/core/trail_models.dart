enum TrailRoute {
  native,
  portal,
  undecided;

  String get storageValue => switch (this) {
    TrailRoute.native => 'native',
    TrailRoute.portal => 'portal',
    TrailRoute.undecided => 'undecided',
  };

  static TrailRoute parse(String? value) => switch (value) {
    'portal' || 'web' => TrailRoute.portal,
    'native' || 'game' => TrailRoute.native,
    _ => TrailRoute.undecided,
  };
}

class RelayReply {
  const RelayReply({
    required this.accepted,
    this.url,
    this.expiresAt,
    this.reason,
  });

  factory RelayReply.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['expires'];
    return RelayReply(
      accepted: json['ok'] == true,
      url: json['url'] is String ? json['url'] as String : null,
      expiresAt: rawExpiry is num
          ? rawExpiry.toInt()
          : int.tryParse(rawExpiry?.toString() ?? ''),
      reason: json['message']?.toString(),
    );
  }

  factory RelayReply.rejected(String reason) =>
      RelayReply(accepted: false, reason: reason);

  final bool accepted;
  final String? url;
  final int? expiresAt;
  final String? reason;

  bool get hasDestination => accepted && (url?.isNotEmpty ?? false);
}

sealed class TrailDestination {
  const TrailDestination();
}

final class NativeTrail extends TrailDestination {
  const NativeTrail();
}

final class PortalTrail extends TrailDestination {
  const PortalTrail(this.url, {this.coldLaunch = false});

  final String url;
  final bool coldLaunch;
}

final class OfflineTrail extends TrailDestination {
  const OfflineTrail({required this.returnToNative});

  final bool returnToNative;
}
