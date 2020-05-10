import 'package:flutter/foundation.dart';

import 'client.dart';
import 'device_info.dart';
import 'session.dart';
import 'store.dart';

class ServiceProvider {
  ServiceProvider(
      {@required String token,
      @required int timeout,
      @required bool getCarrierInfo,
      this.store}) {
    client = Client(token);
    deviceInfo = DeviceInfo(getCarrierInfo);
    session = Session(token, timeout);
    store ??= Store(dbFile: token + '.db');
  }

  Client client;
  Store store;
  Session session;
  DeviceInfo deviceInfo;
}
