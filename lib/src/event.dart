import 'package:uuid/uuid.dart';

class Event {
  static const track = 'track';
  static const engage = 'engage';

  Event(
    this.type,
    this.name, {
    this.id,
    this.distinctId,
    this.sessionId,
    this.timestamp,
    Map<String, dynamic> props,
  }) {
    addProps(props);
    addProp('distinct_id', distinctId);
  }

  String type;
  String name;
  int id;
  int distinctId;
  String sessionId;
  int timestamp;
  Map<String, dynamic> props = <String, dynamic>{};

  void addProps(Map<String, dynamic> props) {
    if (props != null) {
      this.props.addAll(props);
    }
  }

  void addProp(String key, dynamic value) {
    props[key] = value;
  }

  Map<String, dynamic> toPayload(String token) {
    return <String, dynamic>{
      'event': name,
      'properties': {
        'token': token,
        'time': timestamp,
      }..addAll(props),
    };
  }
}
