import 'dart:io';

void main() async {
  var server = await HttpServer.bind('localhost', 3000);
  print('Server is running on ${server.address}:${server.port}');

  await for (var request in server) {
    // Kiểm tra nếu yêu cầu là WebSocket handshake
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      handleWebSocket(request);
    } else {
      // Xử lý các yêu cầu HTTP khác
      request.response.write('Hello, world!');
      await request.response.close();
    }
  }
}

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
