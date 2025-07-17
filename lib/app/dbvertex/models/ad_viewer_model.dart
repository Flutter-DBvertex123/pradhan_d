class AdViewerModel {
  final String adId;
  final String viewerId;
  final String pradhaanId;
  final List<String> scope;

  const AdViewerModel(this.adId, this.viewerId, this.pradhaanId, this.scope);

  Map<String, dynamic> toJson() {
    final json = {
      "ad_id": adId,
      "viewer_id": viewerId,
      "pradhaan_id": pradhaanId,
      "scope": scope
    };
    return json;
  }

  factory AdViewerModel.fromJson(Map json) {
    return AdViewerModel(
        json['ad_id'] ?? '',
        json['viewer_id']??'',
        json['pradhaan_id']??'',
        List<String>.from(json['scope'])
    );
  }
}