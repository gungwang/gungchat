import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identityAsync = ref.watch(deviceIdentityProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Discovery', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Phase 1 focuses on the user flows that will power manual IP, QR, and LAN discovery.',
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.router_outlined),
              title: const Text('Manual IP bootstrap'),
              subtitle: const Text(
                'Use a known IPv4/IPv6 address to exchange an offer, answer, and ICE candidates directly.',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_2_outlined),
              title: const Text('QR exchange'),
              subtitle: identityAsync.when(
                data: (identity) => Text(
                  'Current fingerprint: ${identity.fingerprint}. This will later be embedded into QR contact cards.',
                ),
                loading: () => const Text('Preparing device fingerprint...'),
                error: (error, stackTrace) => Text('Identity unavailable: $error'),
              ),
            ),
          ),
          Card(
            child: const ListTile(
              leading: Icon(Icons.wifi_find_outlined),
              title: Text('LAN discovery'),
              subtitle: Text(
                'Discovery service scaffolding is present. The next step is live mDNS announcements and browsing.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
