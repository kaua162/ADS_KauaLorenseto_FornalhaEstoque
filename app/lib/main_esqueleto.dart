// Esqueleto inicial do app FornalhaEstoque.
// Depois de rodar `flutter create .` na pasta app/, copie este conteúdo
// para lib/main.dart e adicione o pacote http no pubspec.yaml:
//   flutter pub add http

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Ajuste para o IP da sua máquina rodando a API Flask
// (use 10.0.2.2 no emulador Android para acessar o localhost do PC)
const String apiBaseUrl = 'http://10.0.2.2:5000';

void main() => runApp(const FornalhaEstoqueApp());

class FornalhaEstoqueApp extends StatelessWidget {
  const FornalhaEstoqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FornalhaEstoque',
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  String? _mensagemErro;
  bool _carregando = false;

  Future<void> _fazerLogin() async {
    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });
    try {
      final resposta = await http.post(
        Uri.parse('$apiBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'login': _loginController.text,
          'senha': _senhaController.text,
        }),
      );

      if (resposta.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MateriaPrimaPage()),
        );
      } else {
        final corpo = jsonDecode(resposta.body);
        setState(() => _mensagemErro = corpo['erro'] ?? 'Erro ao fazer login.');
      }
    } catch (e) {
      setState(() => _mensagemErro = 'Não foi possível conectar à API.');
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FornalhaEstoque — Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _loginController,
              decoration: const InputDecoration(labelText: 'Usuário'),
            ),
            TextField(
              controller: _senhaController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_mensagemErro != null)
              Text(_mensagemErro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            _carregando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _fazerLogin,
                    child: const Text('Entrar'),
                  ),
          ],
        ),
      ),
    );
  }
}

class MateriaPrimaPage extends StatefulWidget {
  const MateriaPrimaPage({super.key});

  @override
  State<MateriaPrimaPage> createState() => _MateriaPrimaPageState();
}

class _MateriaPrimaPageState extends State<MateriaPrimaPage> {
  List<dynamic> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  Future<void> _carregarItens() async {
    setState(() => _carregando = true);
    final resposta = await http.get(Uri.parse('$apiBaseUrl/materia-prima'));
    if (resposta.statusCode == 200) {
      setState(() {
        _itens = jsonDecode(resposta.body);
        _carregando = false;
      });
    } else {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matéria-Prima')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _itens.length,
              itemBuilder: (context, index) {
                final item = _itens[index];
                final critico = item['estoque_critico'] == true;
                return ListTile(
                  title: Text(item['nome']),
                  subtitle: Text(
                      '${item['qtd_atual']} ${item['unidade_medida']} (mín: ${item['qtd_minima']})'),
                  trailing: critico
                      ? const Icon(Icons.warning, color: Colors.red)
                      : null,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _carregarItens,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
