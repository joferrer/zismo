import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key? key, this.result, this.onTap}) : super(key: key);

  final ScanResult? result;
  final VoidCallback? onTap;

  Widget _buildTitle(BuildContext context) {
    int devNameLength = result?.device.name.length ?? 0;
    String devName = result?.device.name ?? "";
    String devId = result?.device.id.toString() ?? "";
    if (devNameLength > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            devName,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            devId,
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(devId);
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  ?.apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String? getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String? getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    String rssi = result?.rssi.toString() ?? "";
    bool isConnectable = result?.advertisementData.connectable ?? false;
    String localName = result?.advertisementData.localName ?? "";
    int poweLevel = result?.advertisementData.txPowerLevel ?? 0;
    Map<int, List<int>> manufactureData =
        result?.advertisementData.manufacturerData ?? Map.identity();

    bool uuidsEmpty =
        result?.advertisementData.serviceUuids.isNotEmpty ?? false;
    List<String> servUuids =
        result?.advertisementData.serviceUuids ?? List.empty();

    Map<String, List<int>> servData =
        result?.advertisementData.serviceData ?? Map.identity();

    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(rssi),
      trailing: RaisedButton(
        child: Text('CONNECT'),
        color: Colors.black,
        textColor: Colors.white,
        onPressed: (isConnectable) ? onTap : null,
      ),
      children: <Widget>[
        _buildAdvRow(context, 'Complete Local Name', localName),
        _buildAdvRow(context, 'Tx Power Level', '$poweLevel '),
        _buildAdvRow(context, 'Manufacturer Data',
            getNiceManufacturerData(manufactureData) ?? 'N/A'),
        _buildAdvRow(context, 'Service UUIDs',
            (uuidsEmpty) ? servUuids.join(', ').toUpperCase() : 'N/A'),
        _buildAdvRow(
            context, 'Service Data', getNiceServiceData(servData) ?? 'N/A'),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  final BluetoothService? service;
  final List<CharacteristicTile>? characteristicTiles;

  const ServiceTile({Key? key, this.service, this.characteristicTiles})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    int characLength = characteristicTiles?.length ?? 0;
    List<CharacteristicTile> c = characteristicTiles ?? List.empty();
    String servUiid =
        service?.uuid.toString().toUpperCase().substring(4, 8) ?? "";
    if (characLength > 0) {
      return ExpansionTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Service'),
            Text('0x$servUiid',
                style: Theme.of(context).textTheme.bodyText1!.copyWith(
                    color: Theme.of(context).textTheme.caption?.color))
          ],
        ),
        children: c,
      );
    } else {
      return ListTile(
        title: const Text('Service'),
        subtitle: Text('0x$servUiid'),
      );
    }
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic? characteristic;
  final List<DescriptorTile>? descriptorTiles;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;
  final VoidCallback? onNotificationPressed;

  const CharacteristicTile(
      {Key? key,
      this.characteristic,
      this.descriptorTiles,
      this.onReadPressed,
      this.onWritePressed,
      this.onNotificationPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String charUiid =
        characteristic?.uuid.toString().toUpperCase().substring(4, 8) ?? "";

    bool isNoty = characteristic?.isNotifying ?? false;

    return StreamBuilder<List<int>>(
      stream: characteristic?.value,
      initialData: characteristic?.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        return ExpansionTile(
          title: ListTile(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Characteristic'),
                Text('0x$charUiid',
                    style: Theme.of(context).textTheme.bodyText1?.copyWith(
                        color: Theme.of(context).textTheme.caption?.color))
              ],
            ),
            subtitle: Text(value.toString()),
            contentPadding: const EdgeInsets.all(0.0),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.file_download,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                ),
                onPressed: onReadPressed,
              ),
              IconButton(
                icon: Icon(Icons.file_upload,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                onPressed: onWritePressed,
              ),
              IconButton(
                icon: Icon(isNoty ? Icons.sync_disabled : Icons.sync,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                onPressed: onNotificationPressed,
              )
            ],
          ),
          children: descriptorTiles ?? List.empty(),
        );
      },
    );
  }
}

class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor? descriptor;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;

  const DescriptorTile(
      {Key? key, this.descriptor, this.onReadPressed, this.onWritePressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Descriptor'),
          Text('0x${descriptor?.uuid.toString().toUpperCase().substring(4, 8)}',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(color: Theme.of(context).textTheme.caption?.color))
        ],
      ),
      subtitle: StreamBuilder<List<int>>(
        stream: descriptor?.value,
        initialData: descriptor?.lastValue,
        builder: (c, snapshot) => Text(snapshot.data.toString()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: Icon(
              Icons.file_download,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: onReadPressed,
          ),
          IconButton(
            icon: Icon(
              Icons.file_upload,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            onPressed: onWritePressed,
          )
        ],
      ),
    );
  }
}

class AdapterStateTile extends StatelessWidget {
  const AdapterStateTile({Key? key, @required this.state}) : super(key: key);

  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      child: ListTile(
        title: Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subtitle1,
        ),
        trailing: Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subtitle1?.color,
        ),
      ),
    );
  }
}
