import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/estados.dart';
import '../widgets/formulario.dart';
import '../widgets/mensagens.dart';

/// RF05 - Registrar produção de um lote de pizzas congeladas.
class ProducaoScreen extends StatefulWidget {
  const ProducaoScreen({super.key});

  @override
  State<ProducaoScreen> createState() => _ProducaoScreenState();
}

class _ProducaoScreenState extends State<ProducaoScreen> {
  final _form = GlobalKey<FormState>();
  final _quantidade = TextEditingController();
  late Future<List<PizzaSabor>> _sabores = ApiClient.instance.listarSabores();
  int? _idSabor;
  DateTime? _data;
  bool _enviando = false;

  @override
  void dispose() {
    _quantidade.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data ?? hoje,
      firstDate: DateTime(hoje.year - 1),
      lastDate: hoje,
      helpText: 'Data de produção',
    );
    if (escolhida != null) setState(() => _data = escolhida);
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final lote = await ApiClient.instance.registrarProducao(
        idSabor: _idSabor!,
        quantidade: int.parse(_quantidade.text.trim()),
        dataProducao: _data,
      );
      if (!mounted) return;
      mostrarMensagem(
        context,
        '${lote.quantidadeDisponivel} pizzas de ${lote.sabor ?? 'sabor'} adicionadas ao estoque.',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PizzaSabor>>(
      future: _sabores,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done || snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Registrar produção')),
            body: snap.hasError
                ? EstadoErro(
                    mensagem: snap.error.toString(),
                    onTentarNovamente: () => setState(() {
                      _sabores = ApiClient.instance.listarSabores();
                    }),
                  )
                : const Carregando(),
          );
        }
        final sabores = snap.data!;
        return TelaFormulario(
          titulo: 'Registrar produção',
          formKey: _form,
          enviando: _enviando,
          textoBotao: 'Adicionar ao estoque',
          onSalvar: _salvar,
          campos: [
            DropdownButtonFormField<int>(
              initialValue: _idSabor,
              decoration: const InputDecoration(labelText: 'Sabor'),
              items: [for (final s in sabores) DropdownMenuItem(value: s.id, child: Text(s.nome))],
              onChanged: (v) => setState(() => _idSabor = v),
              validator: (v) => v == null ? 'Escolha o sabor' : null,
            ),
            TextFormField(
              controller: _quantidade,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade produzida', suffixText: 'pizzas'),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Informe um número inteiro maior que zero';
                return null;
              },
            ),
            InkWell(
              onTap: _escolherData,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data de produção (opcional)',
                  suffixIcon: _data == null
                      ? const Icon(Icons.calendar_today_outlined)
                      : IconButton(
                          tooltip: 'Usar hoje',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() => _data = null),
                        ),
                ),
                child: Text(
                  _data == null ? 'Hoje' : formatarDataCompleta(_data!),
                  style: TextStyle(color: _data == null ? Cores.textoSecundario : Cores.texto, fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
