import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:socket_io_client/socket_io_client.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';


Future<dynamic> loadConfig() async {
  String configString = await rootBundle.loadString('config.json', cache: false);
  return json.decode(configString);
}

// void ErrorScreenBuild(BuildContext context) {
//   String message;
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => ErrorScreen(message: message)),
//     );
//   }

class ErrorScreen extends StatelessWidget {
  ErrorScreen({super.key, required this.message});

  String message;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '500', style: TextStyle(fontSize: 300),
            ),
            Text(
              message,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: MediaQuery.of(context).size.width > 600 ? 50.0 : 20.0
              ),
            ),
          ],
        ),
      ),
    );
  }
}

var config;

void handleConnection(Socket socket) {
  Socket socket;
}

void main() async {

  runApp(MyApp());

  // while (true) {
  //   try {
  //     var server = await ServerSocket.bind('127.0.0.1', 3003, backlog: 2, shared: true);
  //     print('Server is running on ${server.address}:${server.port}');

  //     await for (var socket in server) {
  //       // handleConnection(socket);
  //       print('Client connected from ${socket.remoteAddress}:${socket.remotePort}');
  //     }
  //   } catch (e) {
  //     print('Error occurred: $e');
  //   }
  // }
  

//   var server = await ServerSocket.bind('127.0.0.1', 3003, backlog: 2, shared: true);
//   print('Server is running on ${server.address}:${server.port}');


// await for (var socket in server) {
//     print('Client connected from ${socket.remoteAddress}:${socket.remotePort}');

//   socket.listen(
//     (Uint8List data) {
//       print('Received data: ${String.fromCharCodes(data)}');

//       socket.write({"a" : "b"});

//       // socket.write('Server received your message: ${String.fromCharCodes(data)}');
//     },
//     // onDone: () {
//     //   print('Client disconnected');
//     // },
//     // onError: (error) {
//     //   print('Error: $error');
//     //   socket.close();
//     // },
//   );
  }
  

  // await for (var request in [server]) {
  //   // Kiểm tra nếu yêu cầu là WebSocket handshake
  //   if (WebSocketTransformer.isUpgradeRequest(request)) {
  //     handleWebSocket(request);
  //   } else {
  //     // Xử lý các yêu cầu HTTP khác
  //     request.response.write('Hello, world!');
  //     await request.response.close();
  //   }
  // }
// }

void handleWebSocket(HttpRequest request) {
  WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
    print('WebSocket connection established');

    webSocket.listen(
      (data) {
        print('Received: $data');
        // Xử lý dữ liệu nhận được từ client ở đây
        webSocket.add('Server received: $data'); // Gửi dữ liệu trả lại cho client
      },
      onDone: () {
        print('WebSocket connection closed');
      },
      onError: (error) {
        print('Error: $error');
      },
    );
  });
}


// void main() async {

//   // var server = await ServerSocket.bind('127.0.0.1', 3003);
//   // print('Server listening on ${server.address}:${server.port}');

//   // await for (var socket in server) {
//   //   print('Client connected from ${socket.remoteAddress}:${socket.remotePort}');

//   // // Đọc dữ liệu từ client
//   // socket.listen(
//   //   (Uint8List data) {
//   //     print('Received data: ${String.fromCharCodes(data)}');
//   //     // Xử lý dữ liệu nhận được
//   //     // Ví dụ: trả lại thông điệp cho client
//   //     socket.write('Server received your message: ${String.fromCharCodes(data)}');
//   //   },
//   //   onDone: () {
//   //     print('Client disconnected');
//   //   },
//   //   onError: (error) {
//   //     print('Error: $error');
//   //     socket.close();
//   //   },
//   // );
//   // }
//   final wsUrl = Uri.parse('ws://localhost:3001');
//   // final channel = WebSocketChannel.connect(wsUrl);
//   final channel = IOWebSocketChannel.connect(wsUrl);

//   // await channel.ready;

//   channel.stream.listen((message) {
//     channel.sink.add('received!');
//     // channel.sink.close(status.goingAway);
//   });
//   runApp(MyApp());
// }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SocketConnectScreen(),
    );
  }
}

class SocketConnectScreen extends StatefulWidget {
  @override
  _SocketConnectScreenState createState() => _SocketConnectScreenState();
}

class _SocketConnectScreenState extends State<SocketConnectScreen> {
  late Socket socket;
  bool isErrorPage = false;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadConfig().then((value) {
      config = value;
      connectToSocket();
    });
    
    
  }

  void connectToSocket() async {
    try {
      // dynamic config = await loadConfig();
      String url = config['socket_url'];
      socket = io(url,
        OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build()
      );
      socket.connect();

      socket.onConnect((_) {
        setState(() {
          isLoading = false;
        });
        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(socket: socket),
          ),
        );
      });

      socket.onDisconnect((_) {
        print('disconnect');
        // setState(() {
        //   isLoading = false;
        //   errorMessage = 'disconnect';
        // });
        
      });
      socket.on('error', (error) {
        print('error');
        // setState(() {
        //   isLoading = false;
        //   errorMessage = error;
        // });
      });
      
    } catch (e) {
      print(e);
      // setState(() {
      //   isLoading = false;
      //   errorMessage = e.toString();
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Connecting',
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),

            isLoading
            ? const CircularProgressIndicator()
            : errorMessage != null
                ? Text('Error: $errorMessage')
                : Container(),
          ],
        )
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.socket });

  final Socket socket;

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {

  String? base64String;
  String? price;

  double imageWidth = 600.0;
  double imageHeight = 600.0;

  @override
  void initState() {
    try {
      super.initState();

      // loadConfig().then((config) {
        widget.socket.on(config['socket_event'], (value) {
          // rootBundle.loadString('config.json', cache: false).then((configInAssets) {
          //   print(configInAssets);
          // });
          dynamic data = jsonDecode(value);
          print('config: $config');

          if(data is Map && data.containsKey('data')) {
            dynamic object = jsonDecode(data['data']);

            if (object is Map) {
              base64String = object.containsKey('qrBase64') ? object['qrBase64']: null;
              price = object.containsKey('price') ? object['price']: null;
              if (base64String != null) {
                switch (base64String) {
                  case 'CLOSE':
                    setState(() {
                      base64String = 'DONE';
                      price = null;
                    });
                    break;
                  default:
                    setState(() {});
                    break;
                }
              }
            }
          }

          if (config['image_width'] is num) {
            imageWidth = config['image_width'];
          }

          if (config['image_height'] is num) {
            imageHeight = config['image_height'];
          }
        });
      // });
      
    } catch (e) {
      print('loi: $e');
//       WidgetsBinding.instance.addRenderView(
// Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ErrorScreen(message: e.toString()),
//         ),
//       )
//       )
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Image
            base64String == null
              ? const Text('')
              : base64String == 'DONE'
                ? const Text('DONE')
                : Image.memory(
                    base64Decode(base64String!),
                    width: MediaQuery.of(context).size.width <= 600 ? 300.0 : imageWidth,
                    height: MediaQuery.of(context).size.width <= 600 ? 300.0 : imageHeight,
                    fit: BoxFit.cover,
                  ),
            const Text(''),
            // Price
            price == null 
              ? const Text('') 
              : Text(
                'Thành tiền: $price VND',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width > 600 ? 55: 25.0,
                ),
              ),
            // Countdown(
            //   animation: StepTween(
            //     begin: levelClock, // THIS IS A USER ENTERED NUMBER
            //     end: 0,
            //   ).animate(_controller),
            // ),
          ],
        ),
      ),
    );
  }
}
