import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/contact.dart';

class ContactBookStorage {
  static const _contactsKey = 'contacts.book';

  const ContactBookStorage();

  Future<List<Contact>> loadContacts() async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(_contactsKey);
    if (rawValue == null || rawValue.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(rawValue) as List<dynamic>;
    return decoded
        .map((item) => Contact.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveContacts(List<Contact> contacts) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      contacts.map((contact) => contact.toJson()).toList(growable: false),
    );
    await preferences.setString(_contactsKey, payload);
  }
}
