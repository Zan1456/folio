// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:math';

import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/api/providers/database_provider.dart';
import 'package:folio/models/user.dart';
import 'package:folio_kreta_api/client/api.dart';
import 'package:folio_kreta_api/client/client.dart';
import 'package:folio_kreta_api/demo/demo_data.dart';
import 'package:folio_kreta_api/models/message.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MessageProvider with ChangeNotifier {
  late List<Message> _messages;
  late List<SendRecipient> _recipients;
  late BuildContext _context;

  List<Message> get messages => _messages;
  List<SendRecipient> get recipients => _recipients;

  MessageProvider({
    List<Message> initialMessages = const [],
    required BuildContext context,
  }) {
    _messages = List.castFrom(initialMessages);
    _recipients = [];
    _context = context;

    if (_messages.isEmpty) restore();
    if (_recipients.isEmpty) restoreRecipients();
  }

  Future<void> restore() async {
    String? userId = Provider.of<UserProvider>(_context, listen: false).id;

    // Load messages from the database
    if (userId != null) {
      var dbMessages =
          await Provider.of<DatabaseProvider>(_context, listen: false)
              .userQuery
              .getMessages(userId: userId);
      _messages = dbMessages;
      notifyListeners();
    }
  }

  // Fetches all types of Messages in parallel
  Future<void> fetchAll() =>
      Future.wait(MessageType.values.map((v) => fetch(type: v)));

  // Fetches Messages from the Kreta API then stores them in the database
  Future<void> fetch({MessageType type = MessageType.inbox}) async {
    // Check Message Type
    if (type == MessageType.draft) return;

    // Check User
    User? user = Provider.of<UserProvider>(_context, listen: false).user;
    if (user == null) throw "Cannot fetch Messages for User null";

    if (DemoData.isDemo(user.id)) {
      if (type == MessageType.inbox) {
        await store(DemoData.messages, type);
      }
      return;
    }

    String messageType =
        ["beerkezett", "elkuldott", "torolt"].elementAt(type.index);

    // Get messages
    List? messagesJson = await Provider.of<KretaClient>(_context, listen: false)
        .getAPI(KretaAPI.messages(messageType));
    if (messagesJson == null) throw "Cannot fetch Messages for User ${user.id}";

    // Parse messages
    List<Message> messages = [];
    await Future.wait(List.generate(messagesJson.length, (index) {
      return () async {
        Map message = messagesJson.cast<Map>()[index];
        Map? messageJson =
            await Provider.of<KretaClient>(_context, listen: false)
                .getAPI(KretaAPI.message(message["azonosito"].toString()));
        if (messageJson != null) {
          messages.add(Message.fromJson(messageJson, forceType: type));
        }
      }();
    }));

    await store(messages, type);
  }

  // Stores Messages in the database
  Future<void> store(List<Message> messages, MessageType type) async {
    // Only store the specified type
    _messages.removeWhere((m) => m.type == type);
    _messages.addAll(messages);

    User? user = Provider.of<UserProvider>(_context, listen: false).user;
    if (user == null) throw "Cannot store Messages for User null";

    String userId = user.id;
    await Provider.of<DatabaseProvider>(_context, listen: false)
        .userStore
        .storeMessages(_messages, userId: userId);

    notifyListeners();
  }

  // restore recipients
  Future<void> restoreRecipients() async {
    String? userId = Provider.of<UserProvider>(_context, listen: false).id;

    // Load messages from the database
    if (userId != null) {
      var dbRecipients =
          await Provider.of<DatabaseProvider>(_context, listen: false)
              .userQuery
              .getRecipients(userId: userId);
      _recipients = dbRecipients;
      notifyListeners();
    }
  }

  // Fetches all recipient types in a single round-trip (3 parallel requests).
  // Previously this called fetchRecipients() once per AddresseeType, which
  // duplicated the same 3 API calls for each type.
  Future<void> fetchAllRecipients() async {
    User? user = Provider.of<UserProvider>(_context, listen: false).user;
    if (user == null) throw "Cannot fetch Recipients for User null";

    if (DemoData.isDemo(user.id)) return;

    final kreta = Provider.of<KretaClient>(_context, listen: false);

    // Fetch categories, teachers and directorate in parallel
    final results = await Future.wait([
      kreta.getAPI(KretaAPI.recipientCategories),
      kreta.getAPI(KretaAPI.recipientTeachers),
      kreta.getAPI(KretaAPI.recipientDirectorate),
    ]);

    List? availableCategoriesJson = results[0];
    List? recipientTeachersJson = results[1];
    List? recipientDirectorateJson = results[2];

    if (availableCategoriesJson == null ||
        recipientTeachersJson == null ||
        recipientDirectorateJson == null) {
      throw "Cannot fetch Recipients for User ${user.id}";
    }

    Map<AddresseeType, SendRecipientType> addressable = {};
    for (var e in availableCategoriesJson) {
      switch (e['kod']) {
        case 'TANAR':
          addressable
              .addAll({AddresseeType.teachers: SendRecipientType.fromJson(e)});
          break;
        case 'IGAZGATOSAG':
          addressable.addAll(
              {AddresseeType.directorate: SendRecipientType.fromJson(e)});
          break;
        default:
          break;
      }
    }

    List<SendRecipient> recipients = [];

    if (addressable.containsKey(AddresseeType.teachers)) {
      recipients.addAll(recipientTeachersJson.map((e) =>
          SendRecipient.fromJson(e, addressable[AddresseeType.teachers]!)));
    }
    if (addressable.containsKey(AddresseeType.directorate)) {
      recipients.addAll(recipientDirectorateJson.map((e) =>
          SendRecipient.fromJson(e, addressable[AddresseeType.directorate]!)));
    }

    _recipients = recipients;
    await Provider.of<DatabaseProvider>(_context, listen: false)
        .userStore
        .storeRecipients(_recipients, userId: user.id);
    notifyListeners();
  }

  // send message
  Future<String?> sendMessage({
    required List<SendRecipient> recipients,
    String subject = "Nincs tárgy",
    required String messageText,
  }) async {
    List<Object> recipientList = [];

    User? user = Provider.of<UserProvider>(_context, listen: false).user;
    if (user == null) throw "Cannot send Message as User null";

    // for (var r in recipients) {
    //   recipientList.add({
    //     "azonosito": r.id ?? "",
    //     "kretaAzonosito": r.kretaId ?? "",
    //     "nev": r.name ?? "Teszt Lajos",
    //     "tipus": {
    //       "kod": r.type.code,
    //       "leiras": r.type.description,
    //       "azonosito": r.type.id,
    //       "nev": r.type.name,
    //       "rovidNev": r.type.shortName,
    //     }
    //   });
    // }
    recipientList.addAll(recipients.map((e) => e.kretaJson));

    Map body = {
      "cimzettLista": recipientList,
      "csatolmanyok": [],
      "azonosito": (Random().nextInt(10000) + 10000),
      "feladoNev": user.name,
      "feladoTitulus": user.role == Role.parent ? "Szülő" : "Diák",
      "kuldesDatum": DateTime.now().toIso8601String(),
      "targy": subject,
      "szoveg": messageText,
      // "elozoUzenetAzonosito": 0,
    };

    Map<String, String> headers = {
      "content-type": "application/json",
    };

    var res = await Provider.of<KretaClient>(_context, listen: false).postAPI(
      KretaAPI.sendMessage,
      autoHeader: true,
      json: true,
      body: json.encode(body),
      headers: headers,
    );

    if (res!['hibakod'] == 'UzenetKuldesEngedelyRule') {
      return 'send_permission_error';
    }

    return 'successfully_sent';
  }
}
