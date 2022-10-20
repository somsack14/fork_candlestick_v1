import 'dart:convert';
import 'package:example/depth_stream_model.dart';

import './candle_ticker_model.dart';
import './repository.dart';
import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool themeIsDark = true;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeIsDark ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: CandlesStickCustom(),
    );
  }
}

class CandlesStickCustom extends StatefulWidget {
  const CandlesStickCustom({Key? key}) : super(key: key);

  @override
  _CandlesStickCustomState createState() => _CandlesStickCustomState();
}

class _CandlesStickCustomState extends State<CandlesStickCustom> {
  BinanceRepository repository = BinanceRepository();

  List<Candle> candles = [];
  DepthStreamModel? depths;
  WebSocketChannel? _channel;
  WebSocketChannel? _depthChannel;
  bool themeIsDark = false;
  String currentInterval = "1m";

  ///check Color
  int? isIndexIntervals = 0;
  final intervals = [
    '1m',
    '5m',
    '15m',
    '30m',
    '1h',
    '1d',
    '1w',
    '1M',
  ];
  List<String> symbols = [];
  String currentSymbol = "";
  List<Indicator> indicators = [
    BollingerBandsIndicator(
      length: 20,
      stdDev: 2,
      upperColor: const Color(0xFF2962FF),
      basisColor: const Color(0xFFFF6D00),
      lowerColor: const Color(0xFF2962FF),
    ),
    WeightedMovingAverageIndicator(
      length: 100,
      color: Colors.green.shade600,
    ),
  ];

  @override
  void initState() {
    fetchSymbols().then((value) {
      symbols = value;
      if (symbols.isNotEmpty) {
        fetchCandles(symbols[0], currentInterval);
        fetchDepthData(symbols[0]);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_channel != null) _channel!.sink.close();
    if (_depthChannel != null) _depthChannel!.sink.close();
    super.dispose();
  }

  Future<List<String>> fetchSymbols() async {
    try {
      // load candles info
      final data = await repository.fetchSymbols();
      return data;
    } catch (e) {
      // handle error
      return [];
    }
  }

  Future<void> fetchCandles(String symbol, String interval) async {
    // close current channel if exists
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    // clear last candle list
    setState(() {
      candles = [];
      currentInterval = interval;
    });

    try {
      // load candles info
      final data =
          await repository.fetchCandles(symbol: symbol, interval: interval);
      // connect to binance stream
      _channel =
          repository.establishConnection(symbol.toLowerCase(), currentInterval);
      // update candles
      setState(() {
        candles = data;
        currentInterval = interval;
        currentSymbol = symbol;
      });
    } catch (e) {
      // handle error
      return;
    }
  }

  Future<void> fetchDepthData(
    String symbol,
  ) async {
    _depthChannel = repository.depthDataConnection(
      symbol.toLowerCase(),
    );
  }

  void updateCandlesFromSnapshot(AsyncSnapshot<Object?> snapshot) {
    if (candles.isEmpty) return;
    if (snapshot.data != null) {
      final map = jsonDecode(snapshot.data as String) as Map<String, dynamic>;

      if (map.containsKey("data") == true) {
        final candleTicker = CandleTickerModel.fromJson(map);

        // cehck if incoming candle is an update on current last candle, or a new one
        if (candles[0].date == candleTicker.candle.date &&
            candles[0].open == candleTicker.candle.open) {
          // update last candle
          candles[0] = candleTicker.candle;
        }
        // check if incoming new candle is next candle so the difrence
        // between times must be the same as last existing 2 candles
        else if (candleTicker.candle.date.difference(candles[0].date) ==
            candles[0].date.difference(candles[1].date)) {
          // add new candle to list
          candles.insert(0, candleTicker.candle);
        }
      }
    }
  }

  void updateDepthFromSnapshot(AsyncSnapshot<Object?> snapshot) {
    if (snapshot.data != null) {
      final map = jsonDecode(snapshot.data as String) as Map<String, dynamic>;
      if (map.containsKey("data") == true) {
        final depthTicker = DepthStreamModel.fromJson(map);
        depths = depthTicker;
      } else {
        final depthTicker = DepthStreamModel.fromJson(map);
        depths = depthTicker;
      }
    }
  }

  Future<void> loadMoreCandles() async {
    try {
      // load candles info
      final data = await repository.fetchCandles(
          symbol: currentSymbol,
          interval: currentInterval,
          endTime: candles.last.date.millisecondsSinceEpoch);
      candles.removeLast();
      setState(() {
        candles.addAll(data);
      });
    } catch (e) {
      // handle error
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Binance Candles"),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                themeIsDark = !themeIsDark;
              });
            },
            icon: Icon(
              themeIsDark
                  ? Icons.wb_sunny_sharp
                  : Icons.nightlight_round_outlined,
            ),
          )
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.07,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text("Sell"),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text("Buy"),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.eighteen_mp),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.access_time_outlined),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        children: [
          Container(
            height: 500,
            width: double.infinity,
            child: StreamBuilder(
              stream: _channel == null ? null : _channel!.stream,
              builder: (context, snapshot) {
                updateCandlesFromSnapshot(snapshot);
                return Candlesticks(
                  key: Key(currentSymbol + currentInterval),
                  indicators: indicators,
                  candles: candles,
                  onLoadMoreCandles: loadMoreCandles,
                  onRemoveIndicator: (String indicator) {
                    setState(() {
                      indicators = [...indicators];
                      indicators
                          .removeWhere((element) => element.name == indicator);
                    });
                  },
                  changeIntervals: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 40,
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: ClampingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: intervals.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                fetchCandles(currentSymbol, intervals[index]);
                                isIndexIntervals = index;
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Container(
                                  width: 40,
                                  child: Center(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          intervals[index],
                                        ),
                                        if (isIndexIntervals == index) ...[
                                          Spacer(),
                                          Container(
                                            width: double.infinity,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    ToolBarAction(
                      onPressed: () {},
                      child: Text(
                        currentInterval,
                      ),
                    ),
                    ToolBarAction(
                      width: 100,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return SymbolsSearchModal(
                              symbols: symbols,
                              onSelect: (value) {
                                fetchCandles(value, currentInterval);
                              },
                            );
                          },
                        );
                      },
                      child: Text(
                        currentSymbol,
                      ),
                    )
                  ],
                );
              },
            ),
          ),
          Container(
            // color: Colors.blue,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Accumulation"),
                  Text("Price"),
                  Text("Accumulation"),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            child: StreamBuilder(
              stream: _depthChannel == null ? null : _depthChannel!.stream,
              builder: (context, snapshot) {
                updateDepthFromSnapshot(snapshot);
                return depths == null
                    ? Container()
                    : depths!.data == null
                        ? Container()
                        : Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 2),
                                    child: ListView.builder(
                                        physics: ClampingScrollPhysics(),
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: depths!.data!.bids!.length,
                                        itemBuilder: (context, v) {
                                          var count = v + 1;
                                          var depthColorLeft = double.tryParse(
                                              depths!.data!.bids![v][1])!;
                                          debugPrint(
                                              "depthColorLeft $depthColorLeft");
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Stack(
                                              children: [
                                                Positioned(
                                                  child: Container(
                                                    color:
                                                        Colors.green.shade700,
                                                    width: depthColorLeft * 100,
                                                    height: 20,
                                                  ),
                                                ),
                                                Container(
                                                  height: 20,
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        flex: 2,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      5),
                                                          child:
                                                              Text("$count "),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 5,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: Text(
                                                              "${double.tryParse(depths!.data!.bids![v][0])}"),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 5,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                              "${double.tryParse(depths!.data!.bids![v][1])}"),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                  ),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Expanded(
                                  child: ListView.builder(
                                      physics: ClampingScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: depths!.data!.asks!.length,
                                      itemBuilder: (context, e) {
                                        var count = e + 1;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 5,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                      "${double.tryParse(depths!.data!.asks![e][1])}"),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 5,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                      "${double.tryParse(depths!.data!.asks![e][0])}"),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 5),
                                                  child: Text("$count "),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                )
                              ],
                            ),
                          );
              },
            ),
          )
        ],
      ),
    );
  }
}

class SymbolsSearchModal extends StatefulWidget {
  const SymbolsSearchModal({
    Key? key,
    required this.onSelect,
    required this.symbols,
  }) : super(key: key);

  final Function(String symbol) onSelect;
  final List<String> symbols;

  @override
  State<SymbolsSearchModal> createState() => _SymbolSearchModalState();
}

class _SymbolSearchModalState extends State<SymbolsSearchModal> {
  String symbolSearch = "";
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 300,
          height: 700,
          color: Theme.of(context).backgroundColor.withOpacity(0.5),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CustomTextField(
                  onChanged: (value) {
                    setState(() {
                      symbolSearch = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView(
                  children: widget.symbols
                      .where((element) => element
                          .toLowerCase()
                          .contains(symbolSearch.toLowerCase()))
                      .map((e) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 50,
                              height: 30,
                              child: RawMaterialButton(
                                elevation: 0,
                                fillColor: const Color(0xFF494537),
                                onPressed: () {
                                  widget.onSelect(e);
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  e,
                                  style: const TextStyle(
                                    color: Color(0xFFF0B90A),
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({Key? key, required this.onChanged}) : super(key: key);
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      cursorColor: const Color(0xFF494537),
      decoration: const InputDecoration(
        prefixIcon: Icon(
          Icons.search,
          color: Color(0xFF494537),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(width: 3, color: Color(0xFF494537)), //<-- SEE HER
        ),
        border: OutlineInputBorder(
          borderSide:
              BorderSide(width: 3, color: Color(0xFF494537)), //<-- SEE HER
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(width: 3, color: Color(0xFF494537)), //<-- SEE HER
        ),
      ),
      onChanged: onChanged,
    );
  }
}
