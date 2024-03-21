import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:slide_countdown/slide_countdown.dart';
// import  from '@mui/icons-material/Check';


Future<dynamic> loadConfig() async {
  String configString = await rootBundle.loadString('config.json', cache: false);
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key });

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {

  int keyTimeRunning = 0;

  String? base64String;
  String message = '';
  int expireTime = 0;

  double imageWidth = 600.0;
  double imageHeight = 600.0;
  Socket? socket;

  @override
  void initState() {
    try {
      super.initState();
      loadConfig().then((config) {
        
        imageWidth = config['image_width'] ?? 600.0;
        imageHeight = config['image_height'] ?? 600.0;

        String event = config['socket_event'] ?? 'Laputa';
        int port = config['socket_port'] ?? 8182;

        HttpServer.bind(InternetAddress.loopbackIPv4, port, backlog: 2)
        .then((httpServer) {
          print('socket running in: ${httpServer.address}:${httpServer.port}');
          httpServer.listen((req) {
            if (req.uri.path == '/$event') {
              WebSocketTransformer.upgrade(req).then((socket) {
                socket.listen(
                  (value) {
                    try {

                      dynamic data = jsonDecode(value);
                      if(data is Map && data.containsKey('data')) {
                        dynamic object = jsonDecode(data['data']);

                        if (object is Map) {
                          base64String = object['qrBase64'] ?? 'ERROR';
                          message = object.containsKey('price') ? "Thành tiền: ${formatCurrencyVN(object['price'])}": '';
                          expireTime = object['expireTime'];
                          // expireTime = 1800;

                          if (base64String == 'CLOSE') {
                            setState(() {
                              message = '';
                              expireTime = 15;
                            });

                            Timer(const Duration(milliseconds: 15000), () {
                              setState(() {
                                base64String = null;
                                message = '';
                                expireTime = 0;
                              });
                            });
                          }

                          if (base64String == '') {
                            return setState(() {
                              base64String = 'ERROR';
                              message = 'QR trống';
                              expireTime = 0;
                            });
                          }
                          return setState(() {
                            keyTimeRunning++;
                            print(keyTimeRunning);
                          });
                        }
                      }
                      
                    } catch (e) {
                      setState(() {
                        base64String = 'ERROR';
                        message = e.toString();
                        expireTime = 0;
                      });
                    }
                  },
                  onDone: () {},
                  onError: (e) { 
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
        });

      });

    } catch (e) {
      setState(() {
        base64String = 'ERROR';
        message = e.toString();
        expireTime = 0;
      }); 
    }
  }

  String _formatTime(int remaining) {
    int minutes = remaining ~/ 60;
    int seconds = remaining % 60;
    return '$minutes : $seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
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
                    size: MediaQuery.of(context).size.width > 600 ? 600: 300.0,
                      const IconData(0xe156, fontFamily: 'MaterialIcons')
                    )
                  : base64String == 'ERROR'
                    ? Text(
                      'Lỗi không xác định:',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width > 600 ? 55: 25.0,
                          ),
                      )
                    : isBase64(base64String)
                      ? Image.memory(
                          base64Decode(base64String!),
                          width: MediaQuery.of(context).size.width <= 600 ? 300.0 : imageWidth,
                          height: MediaQuery.of(context).size.width <= 600 ? 300.0 : imageHeight,
                          fit: BoxFit.cover,
                        )
                      : Text(
                          'Không thể gen QR',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width > 600 ? 55: 25.0,
                          ),
                        ),
              Text(
                message,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width > 600 ? 55: 25.0,
                ),
              ),
              expireTime == 0
                ? const Text('')
                : SlideCountdown(
                    key: ValueKey(keyTimeRunning),
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 55: 25.0,
                      fontWeight: FontWeight.bold
                    ),
                    decoration: const BoxDecoration(color: Colors.white),
                    separatorStyle: TextStyle(
                      color: Colors.black,
                      fontSize: MediaQuery.of(context).size.width > 600 ? 50: 20.0,
                      fontWeight: FontWeight.bold
                    ),
                    shouldShowMinutes: (p0) => true,
                    shouldShowSeconds: (p0) => true,
                    duration: Duration(seconds: expireTime),
                    onDone: () {
                      keyTimeRunning = 0;
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
  int amount = int.parse(value);
  // Định dạng tiền tệ Việt Nam
  final currencyFormat = NumberFormat.currency(
    locale: 'vi-VN',
    symbol: 'VND',
    decimalDigits: 0,
  );

  // Chuyển đổi số sang định dạng tiền tệ
  return currencyFormat.format(amount);
}
