import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';
import 'dart:convert' show utf8;

class SensorPage extends StatefulWidget {
  const SensorPage({Key? key, this.device}) : super(key: key);

  final BluetoothDevice? device;

  @override
  _SensorPageState createState() => _SensorPageState();
}

class _SensorPageState extends State<SensorPage> {
  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  bool isReady = true;

  Stream<List<int>>? stream;

  @override
  void initState() {
    super.initState();
    conectToDevice();
  }

  conectToDevice() async {
    if (widget.device == null) {
      _Pop();
      return;
    }

    // ignore: unnecessary_new
    new Timer(const Duration(seconds: 15), () {
      if (!isReady) {
        disconnectFromDevice();
        _Pop();
      }
    });

    await widget.device?.connect();
    discoverServices();
  }

  /// Desconexión del dispositivo.
  disconnectFromDevice() {
    if (widget.device == null) {
      _Pop();
      return;
    }

    widget.device?.disconnect();
  }

  discoverServices() async {
    if (widget.device == null) {
      _Pop();
      return;
    }

    List<BluetoothService>? services = await widget.device?.discoverServices();
    services?.forEach((service) {
      if (service.uuid.toString() == SERVICE_UUID) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            stream = characteristic.value;

            setState(() {
              isReady = true;
            });
          }
        });
      }
    });

    if (!isReady) {
      _Pop();
    }
  }

  Future<bool> _onWillPop() {
    Future<bool?> v = showDialog<bool?>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Are you sure?'),
              content:
                  const Text('Do you want to disconnect device and go back?'),
              actions: <Widget>[
                FlatButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No')),
                FlatButton(
                    onPressed: () {
                      disconnectFromDevice();
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Yes')),
              ],
            ));

    if (v == null) {
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  }

  _Pop() {
    Navigator.of(context).pop(true);
  }

  String _dataParser(List<int>? dataFromDevice) {
    if (dataFromDevice != null) {
      return utf8.decode(dataFromDevice);
    } else {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    Scaffold child = Scaffold(
      appBar: AppBar(
        title: Text("Zismo APP"),
      ),
      body: Container(
        child: !isReady
            ? Center(
                child: Text("Waiting...",
                    style: TextStyle(fontSize: 24, color: Colors.red)))
            : Container(
                child: StreamBuilder<List<int>>(
                    stream: stream,
                    builder: (BuildContext context,
                        AsyncSnapshot<List<int>?> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      if (snapshot.connectionState == ConnectionState.active) {
                        var currentValue = _dataParser(snapshot.data);

                        return Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              flex: 1,
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Text('Current value from Sensor',
                                        style: TextStyle(fontSize: 14)),
                                    Text('$currentValue ug/m3',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24))
                                  ]),
                            ),
                          ],
                        ));
                      } else {
                        return const Text('Check the stream');
                      }
                    }),
              ),
      ),
    );

    return WillPopScope(child: child, onWillPop: _onWillPop);
  }
}
