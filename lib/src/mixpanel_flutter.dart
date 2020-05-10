import 'dart:async';

import 'package:flutter/foundation.dart';

import 'config.dart';
import 'device_info.dart';
import 'event.dart';
import 'event_buffer.dart';
import 'identify.dart';
import 'revenue.dart';
import 'service_provider.dart';
import 'session.dart';

class MixpanelFlutter {
  MixpanelFlutter(String apiKey, [this.config]) {
    config ??= Config();
    provider = ServiceProvider(
      token: apiKey,
      timeout: config.sessionTimeout,
      getCarrierInfo: config.getCarrierInfo,
    );
    _init();
  }

  MixpanelFlutter.private(this.provider, this.config) {
    _init();
  }

  bool getCarrierInfo;
  Config config;
  ServiceProvider provider;
  DeviceInfo deviceInfo;
  Session session;
  EventBuffer buffer;
  dynamic userId;

  /// Set the user id associated with events
  void setUserId(dynamic userId) {
    this.userId = userId;
  }

  /// Log an event
  Future<void> track({
    @required String event,
    Map<String, dynamic> properties = const <String, String>{},
  }) async {
    session.refresh();

    if (config.optOut) {
      return Future.value(null);
    }

    final Event trackEvent = Event(Event.track, event, sessionId: session.getSessionId(), distinctId: userId ?? 'Unknown', props: properties);

    return buffer.add(trackEvent);
  }

  /// Identify the current user
  Future<void> identify(Identify identify, {Map<String, dynamic> properties = const <String, dynamic>{}}) async {
    return track(event: r'$identify', properties: <String, dynamic>{'user_properties': identify.payload}..addAll(properties));
  }

  /// Adds the current user to a group
  Future<void> setGroup(String groupType, dynamic groupValue) async {
    return identify(Identify()..set(groupType, groupValue), properties: <String, dynamic>{
      'groups': <String, dynamic>{groupType: groupValue}
    });
  }

  /// Sets properties on a group
  Future<void> groupIdentify(String groupType, dynamic groupValue, Identify identify) async {
    return track(event: r'$groupidentify', properties: <String, dynamic>{
      'group_properties': identify.payload,
      'groups': <String, dynamic>{groupType: groupValue}
    });
  }

  /// Log a revenue event
  Future<void> logRevenue(Revenue revenue) async {
    if (revenue.isValid()) {
      return track(event: Revenue.EVENT, properties: <String, dynamic>{'event_properties': revenue.payload});
    }
  }

  /// Manually flush events in the buffer
  Future<void> flushEvents() => buffer.flush();

  void _init() {
    deviceInfo = provider.deviceInfo;
    session = provider.session;
    buffer = EventBuffer(provider, config);

    session.start();
  }
}
