import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'client.dart';
import 'config.dart';
import 'event.dart';
import 'service_provider.dart';
import 'store.dart';
import 'time_utils.dart';

class EventBuffer {
  EventBuffer(this.provider, this.config) {
    client = provider.client;
    store = provider.store;
    flushInProgress = false;

    Timer.periodic(
        Duration(seconds: config.flushPeriod), (Timer _t) => flush());
  }

  final Config config;
  final ServiceProvider provider;
  Client client;
  Store store;

  bool flushInProgress;
  int numEvents;

  /// Returns number of events in buffer
  int get length => store.length;

  /// Adds a raw event hash to the buffer
  Future<void> add(Event event) async {
    if (length >= config.maxStoredEvents) {
      print('Max stored events reached.  Discarding event.');
      return;
    }

    event.timestamp = TimeUtils().currentTime();
    await store.add(event);

    if (length >= config.bufferSize) {
      await flush();
    }
  }

  /// Flushes all events in buffer
  Future<void> flush() async {
    if (length < 1 || flushInProgress) {
      return;
    }

    flushInProgress = true;
    numEvents ??= length;
    final events = await fetch(numEvents);
    final trackEvents = events.where((element) => element.type == Event.track);
    final engageEvents = events.where((element) => element.type == Event.engage);
    final trackEventIds = trackEvents.map((e) => e.id).toList();
    final engageEventIds = trackEvents.map((e) => e.id).toList();

    final trackStatus = await client.post(trackEvents, Event.track);
    switch (trackStatus) {
      case 200:
        await _deleteEvents(trackEventIds);
        break;
      case 413:
        await _handlePayloadTooLarge(trackEventIds);
        print('MIXPANEL: PALOAD TO LARGE');
        break;
      default:
      // error
    }

    final engageStatus = await client.post(engageEvents, Event.engage);
    switch (engageStatus) {
      case 200:
        await _deleteEvents(engageEventIds);
        break;
      case 413:
        await _handlePayloadTooLarge(engageEventIds);
        print('MIXPANEL: PALOAD TO LARGE');
        break;
      default:
      // error
    }
    flushInProgress = false;
  }

  @visibleForTesting
  Future<List<Event>> fetch(int count) async {
    assert(count >= 0);

    final endRange = min(count, store.length);
    return await store.fetch(endRange);
  }

  Future<void> _handlePayloadTooLarge(List<int> eventIds) async {
    // drop a single event that is too large
    if (eventIds.length == 1) {
      await _deleteEvents(eventIds);
    } else {
      numEvents = numEvents ~/ 2;
    }
  }

  Future<void> _deleteEvents(List<int> eventIds) async {
    await store.delete(eventIds);
    numEvents = null;
  }
}