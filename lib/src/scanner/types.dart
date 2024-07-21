import 'package:xml/xml.dart';

class Protocol {
  String name;
  String copyright;
  List<Interface> interfaces;

  Protocol(
      {required this.name, required this.copyright, required this.interfaces});

  factory Protocol.fromXml(XmlElement element) {
    return Protocol(
      name: element.getAttribute('name') ?? '',
      copyright: element.findElements('copyright').isEmpty
          ? ''
          : element.findElements('copyright').first.text,
      interfaces: element
          .findElements('interface')
          .map((e) => Interface.fromXml(e))
          .toList(),
    );
  }
}

class Interface {
  String name;
  Description description;
  List<Request> requests;
  List<Event> events;
  List<Enum> enums;
  int version;

  Interface({
    required this.name,
    required this.description,
    required this.requests,
    required this.events,
    required this.enums,
    required this.version,
  });

  factory Interface.fromXml(XmlElement element) {
    return Interface(
      name: element.getAttribute('name') ?? '',
      description: element.findElements('description').isEmpty
          ? Description(text: '', summary: '')
          : Description.fromXml(element.findElements('description').first),
      requests: element
          .findElements('request')
          .map((e) => Request.fromXml(e))
          .toList(),
      events:
          element.findElements('event').map((e) => Event.fromXml(e)).toList(),
      enums: element.findElements('enum').map((e) => Enum.fromXml(e)).toList(),
      version: int.parse(element.getAttribute('version') ?? '0'),
    );
  }
}

class Request {
  String name;
  String type;
  Description description;
  List<Arg> args;
  int since;

  Request({
    required this.name,
    required this.type,
    required this.description,
    required this.args,
    required this.since,
  });

  factory Request.fromXml(XmlElement element) {
    return Request(
      name: element.getAttribute('name') ?? '',
      type: element.getAttribute('type') ?? '',
      description: element.findElements('description').isEmpty
          ? Description(text: '', summary: '')
          : Description.fromXml(element.findElements('description').first),
      args: element.findElements('arg').map((e) => Arg.fromXml(e)).toList(),
      since: int.parse(element.getAttribute('since') ?? '0'),
    );
  }

  bool get isDestructor => type == "destructor";
}

class Event {
  String name;
  String type;
  Description description;
  List<Arg> args;
  int since;

  Event({
    required this.name,
    required this.type,
    required this.description,
    required this.args,
    required this.since,
  });

  factory Event.fromXml(XmlElement element) {
    return Event(
      name: element.getAttribute('name') ?? '',
      type: element.getAttribute('type') ?? '',
      description: element.findElements('description').isEmpty
          ? Description(text: '', summary: '')
          : Description.fromXml(element.findElements('description').first),
      args: element.findElements('arg').map((e) => Arg.fromXml(e)).toList(),
      since: int.parse(element.getAttribute('since') ?? '0'),
    );
  }
}

class Enum {
  String name;
  Description description;
  List<Entry> entries;
  int since;
  bool bitfield;

  Enum({
    required this.name,
    required this.description,
    required this.entries,
    required this.since,
    required this.bitfield,
  });

  factory Enum.fromXml(XmlElement element) {
    return Enum(
      name: element.getAttribute('name') ?? '',
      description: element.findElements('description').isEmpty
          ? Description(text: '', summary: '')
          : Description.fromXml(element.findElements('description').first),
      entries:
          element.findElements('entry').map((e) => Entry.fromXml(e)).toList(),
      since: int.parse(element.getAttribute('since') ?? '0'),
      bitfield: element.getAttribute('bitfield') == 'true',
    );
  }
}

class Entry {
  String name;
  String value;
  String summary;
  Description description;
  int since;

  Entry({
    required this.name,
    required this.value,
    required this.summary,
    required this.description,
    required this.since,
  });

  factory Entry.fromXml(XmlElement element) {
    return Entry(
      name: element.getAttribute('name') ?? '',
      value: element.getAttribute('value') ?? '',
      summary: element.getAttribute('summary') ?? '',
      description: element.findElements('description').isEmpty
          ? Description(text: '', summary: '')
          : Description.fromXml(element.findElements('description').first),
      since: int.parse(element.getAttribute('since') ?? '0'),
    );
  }
}

class Arg {
  String name;
  String type;
  String summary;
  String interface;
  String enum_;
  Description description;
  bool allowNull;

  Arg({
    required this.name,
    required this.type,
    required this.summary,
    required this.interface,
    required this.enum_,
    required this.description,
    required this.allowNull,
  });

  factory Arg.fromXml(XmlElement element) {
    return Arg(
      name: element.getAttribute('name') ?? '',
      type: element.getAttribute('type') ?? '',
      summary: element.getAttribute('summary') ?? '',
      interface: element.getAttribute('interface') ?? '',
      enum_: element.getAttribute('enum') ?? '',
      description: element.findElements('description').isEmpty
          ? Description(text: '', summary: '')
          : Description.fromXml(element.findElements('description').first),
      allowNull: element.getAttribute('allow-null') == 'true',
    );
  }
}

class Description {
  String text;
  String summary;

  Description({required this.text, required this.summary});

  factory Description.fromXml(XmlElement element) {
    return Description(
      text: element.text,
      summary: element.getAttribute('summary') ?? '',
    );
  }
}

// Define Protocol, Interface, Request, Event, Enum, Entry, Arg, and Description classes here
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
