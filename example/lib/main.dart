// Example vault browser for package:onepassword_connect.
//
// Point it at a 1Password Connect server, paste an access token, and browse
// vaults → items → fields with reveal/copy.
//
// On Flutter web the Connect server must be reachable from the browser and
// send CORS headers (see the package README for a reverse-proxy snippet).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onepassword_connect/onepassword_connect.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1Password Connect example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const ConnectPage(),
    );
  }
}

/// Connection form: server URL + token.
class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final _url = TextEditingController(text: 'http://localhost:8081');
  final _token = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final client = OnePasswordConnect(
      serverUrl: Uri.parse(_url.text.trim()),
      token: _token.text.trim(),
    );
    try {
      final vaults = await client.vaults.list();
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VaultsPage(client: client, vaults: vaults),
      ));
      client.close();
    } on OnePasswordException catch (e) {
      client.close();
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1Password Connect example')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _url,
                  decoration: const InputDecoration(
                    labelText: 'Connect server URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _token,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Access token',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _connect,
                  child: Text(_busy ? 'Connecting…' : 'Connect'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _error!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VaultsPage extends StatelessWidget {
  const VaultsPage({super.key, required this.client, required this.vaults});

  final OnePasswordConnect client;
  final List<Vault> vaults;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vaults')),
      body: ListView(
        children: [
          for (final vault in vaults)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(vault.name),
              subtitle: Text('${vault.items ?? '?'} items'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ItemsPage(client: client, vault: vault),
              )),
            ),
        ],
      ),
    );
  }
}

class ItemsPage extends StatelessWidget {
  const ItemsPage({super.key, required this.client, required this.vault});

  final OnePasswordConnect client;
  final Vault vault;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(vault.name)),
      body: FutureBuilder(
        future: client.items.list(vault.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Request failed: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              for (final item in snapshot.data!)
                ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: Text(item.title),
                  subtitle: Text(item.category.value),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ItemDetailPage(
                      client: client,
                      vaultId: vault.id,
                      itemId: item.id!,
                    ),
                  )),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({
    super.key,
    required this.client,
    required this.vaultId,
    required this.itemId,
  });

  final OnePasswordConnect client;
  final String vaultId;
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: client.items.get(vaultId, itemId),
      builder: (context, snapshot) {
        final item = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(item?.title ?? 'Item')),
          body: snapshot.hasError
              ? Center(child: Text('Request failed: ${snapshot.error}'))
              : item == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: [
                        for (final field in item.fields)
                          if ((field.value ?? field.totp) != null)
                            FieldTile(item: item, field: field),
                      ],
                    ),
        );
      },
    );
  }
}

class FieldTile extends StatefulWidget {
  const FieldTile({super.key, required this.item, required this.field});

  final Item item;
  final ItemField field;

  @override
  State<FieldTile> createState() => _FieldTileState();
}

class _FieldTileState extends State<FieldTile> {
  bool _revealed = false;

  bool get _sensitive =>
      widget.field.type == FieldType.concealed ||
      widget.field.type == FieldType.otp;

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final value = field.totp ?? field.value!;
    final label = field.label ?? field.purpose?.value ?? field.id ?? 'field';
    final sectionLabel = widget.item.sections
        .where((s) => s.id == field.section?.id)
        .map((s) => s.label)
        .firstOrNull;

    return ListTile(
      title: Text(_sensitive && !_revealed ? '••••••••' : value,
          style: const TextStyle(fontFamily: 'monospace')),
      subtitle: Text(sectionLabel == null ? label : '$sectionLabel · $label'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_sensitive)
            IconButton(
              icon: Icon(_revealed ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _revealed = !_revealed),
            ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied $label')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
