import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:slide_countdown/slide_countdown.dart';
// import  from '@mui/icons-material/Check';

Future<dynamic> loadConfig() async {
  String configString =
      await rootBundle.loadString('config.json', cache: false);
  return json.decode(configString);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.black,
              ),
            ),

            Expanded(
              flex: 5,
              child: Container(
                alignment: Alignment.center,
                color: Colors.white,
                child: const HomeScreen(),
              ),
            ),

            Expanded(
              flex: 2,
              child: Container(
                color: Colors.black,
                // child: const Center(child: Text('Right Column')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  int keyTimeRunning = 0;
  bool isOkDisplay = false;

  String? base64String;
  String message = '';
  int expireTime = 0;

  double imageWidth = 600.0;
  double imageHeight = 600.0;
  double textSize = 55.0;
  Socket? socket;

  bool isBase64(String? value) {
    try {
      if (value == null) {
        return false;
      }
      return base64.encode(base64.decode(value)) == value;
    } catch (e) {
      return false;
    }
  }

  String formatCurrencyVN(String value) {
    try {
      int amount = int.parse(value);
      // Định dạng tiền tệ Việt Nam
      final currencyFormat = NumberFormat.currency(
        locale: 'vi-VN',
        symbol: 'VND',
        decimalDigits: 0,
      );

      // Chuyển đổi số sang định dạng tiền tệ
      return currencyFormat.format(amount);
    } catch (e) {
      return value;
    }
  }

  String formatTime(int remaining) {
    int minutes = remaining ~/ 60;
    int seconds = remaining % 60;
    return '$minutes : $seconds';
  }

  @override
  void initState() {
    try {
      super.initState();
      loadConfig().then((config) {
        imageWidth = config['image_width'] ?? 600.0;
        imageHeight = config['image_height'] ?? 600.0;
        textSize = config['text_size'] ?? 55.0;

        String event = config['socket_event'] ?? 'Laputa';
        int port = config['socket_port'] ?? 8182;

        HttpServer.bind(InternetAddress.anyIPv4, port, backlog: 2)
            .then((httpServer) {
          // print('socket running in: ${httpServer.address}:${httpServer.port}');
          httpServer.listen((req) {
            if (req.uri.path == '/$event') {
              WebSocketTransformer.upgrade(req).then((socket) {
                socket.listen(
                  (value) {
                    try {
                      dynamic data = jsonDecode(value);
                      if (data is Map && data.containsKey('data')) {
                        dynamic object = jsonDecode(data['data']);

                        if (object is Map) {
                          base64String = object['qrBase64'] ?? 'ERROR';
                          message = object.containsKey('price')
                              ? "Thành tiền: ${formatCurrencyVN(object['price'])}"
                              : '';
                          expireTime = object['expireTime'];

                          if (base64String == 'CLOSE') {
                            setState(() {
                              message = '';
                              expireTime = 15;
                            });
                            isOkDisplay = true;

                            Future.delayed(const Duration(seconds: 15))
                                .then((value) {
                              if (isOkDisplay) {
                                isOkDisplay = false;
                                setState(() {
                                  base64String = null;
                                  message = '';
                                  expireTime = 0;
                                });
                              }
                            });
                          }

                          if (base64String == '') {
                            isOkDisplay = false;
                            return setState(() {
                              base64String = 'ERROR';
                              message = 'QR trống';
                              expireTime = 0;
                            });
                          }

                          isOkDisplay = false;
                          return setState(() {
                            keyTimeRunning++;
                          });
                        }
                      }
                    } catch (e) {
                      isOkDisplay = false;
                      setState(() {
                        base64String = 'ERROR';
                        message = e.toString();
                        expireTime = 0;
                      });
                    }
                  },
                  onDone: () {},
                  onError: (e) {
                    isOkDisplay = false;
                    setState(() {
                      base64String = 'ERROR';
                      message = e.toString();
                      expireTime = 0;
                    });
                  },
                  cancelOnError: false,
                );
              });
            }
          });
        }).catchError((e) {
          isOkDisplay = false;
          setState(() {
            base64String = 'ERROR';
            message = e.toString();
            expireTime = 0;
          });
        }, test: (error) {
          return false;
        }).onError((e, stackTrace) {
          isOkDisplay = false;
          setState(() {
            base64String = 'ERROR';
            message = e.toString();
            expireTime = 0;
          });
        });
      });
    } catch (e) {
      isOkDisplay = false;
      setState(() {
        base64String = 'ERROR';
        message = e.toString();
        expireTime = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        // showTrackOnHover: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            verticalDirection: VerticalDirection.down,
            children: <Widget>[
              // Image
              base64String == null
                  ? const Text('')
                  : base64String == 'CLOSE'
                      ? Icon(
                          size: MediaQuery.of(context).size.width > 600
                              ? imageWidth
                              : 300.0,
                          const IconData(0xe156, fontFamily: 'MaterialIcons'))
                      : base64String == 'ERROR'
                          ? Text(
                              'Lỗi không xác định:',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        MediaQuery.of(context).size.width > 600
                                            ? 55
                                            : 25.0,
                                  ),
                            )
                          : isBase64(base64String)
                              ? Image.memory(
                                  base64Decode(base64String!),
                                  width:
                                      MediaQuery.of(context).size.width <= 600
                                          ? 200.0
                                          : imageWidth,
                                  height:
                                      MediaQuery.of(context).size.width <= 600
                                          ? 200.0
                                          : imageHeight,
                                  fit: BoxFit.cover,
                                )
                              : Text(
                                  'Không thể gen QR: $base64String',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            MediaQuery.of(context).size.width >
                                                    600
                                                ? textSize
                                                : 25.0,
                                      ),
                                ),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width > 600
                          ? textSize
                          : 25.0,
                    ),
              ),
              expireTime == 0
                  ? const Text('')
                  : SlideCountdown(
                      key: ValueKey(keyTimeRunning),
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width > 600
                              ? textSize
                              : 25.0,
                          fontWeight: FontWeight.bold),
                      decoration: const BoxDecoration(color: Colors.white),
                      separatorStyle: TextStyle(
                          color: Colors.black,
                          fontSize: MediaQuery.of(context).size.width > 600
                              ? textSize - 5
                              : 20.0,
                          fontWeight: FontWeight.bold),
                      shouldShowMinutes: (p0) => true,
                      shouldShowSeconds: (p0) => true,
                      duration: Duration(seconds: expireTime + 2),
                      onDone: () {
                        keyTimeRunning = 0;
                        isOkDisplay = false;
                        return setState(() {
                          base64String = null;
                          message = '';
                          expireTime = 0;
                        });
                      },
                    )
            ],
          ),
        ),
      ),
    );
  }
}
