class DepthStreamModel {
  String? stream;
  Data? data;

  DepthStreamModel({this.stream, this.data});

  DepthStreamModel.fromJson(Map<String, dynamic> json) {
    stream = json['stream'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['stream'] = this.stream;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? lastUpdateId;
  List? bids;
  List? asks;

  Data({this.lastUpdateId, this.bids, this.asks});

  Data.fromJson(Map<String, dynamic> json) {
    lastUpdateId = json['lastUpdateId'];
    if (json['bids'] != null) {
      bids = [];
      json['bids'].forEach((v) {
        bids!.add(v);
      });
    }
    if (json['asks'] != null) {
      asks = [];
      json['asks'].forEach((v) {
        asks!.add(v);
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lastUpdateId'] = this.lastUpdateId;
    if (this.bids != null) {
      data['bids'] = this.bids!.map((v) => v.toJson()).toList();
    }
    if (this.asks != null) {
      data['asks'] = this.asks!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
