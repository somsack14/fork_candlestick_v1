import 'package:candlesticks/candlesticks.dart';

class CandleTickerModel {
  final int eventTime;
  final String symbol;
  final Candle candle;

  const CandleTickerModel(
      {required this.eventTime, required this.symbol, required this.candle});

  factory CandleTickerModel.fromJson(Map<String, dynamic> json) {
    return CandleTickerModel(
        eventTime: json["data"]['E'] as int,
        symbol: json["data"]['s'] as String,
        candle: Candle(
            date: DateTime.fromMillisecondsSinceEpoch(json["data"]["k"]["t"]),
            high: double.parse(json["data"]["k"]["h"]),
            low: double.parse(json["data"]["k"]["l"]),
            open: double.parse(json["data"]["k"]["o"]),
            close: double.parse(json["data"]["k"]["c"]),
            volume: double.parse(json["data"]["k"]["v"])));
  }
}
