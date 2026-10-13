import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../utils/formatos.dart';
import '../widgets/formulario.dart';
import '../widgets/mensagens.dart';

/// RF02 - HU03: cadastrar (ou editar) insumo.
class InsumoFormScreen extends StatefulWidget {
  const InsumoFormScreen({super.key, this.insumo});

  /// Se informado, edita. A quantidade atual não é editável (muda por movimentação).
  final MateriaPrima? insumo;

  @override
  State<InsumoFormScreen> createState() => _InsumoFormScreenState();
}

class _InsumoFormScreenState extends State<InsumoFormScreen> {
  /// Unidades previstas no model materia_prima.
  static const unidades = ['kg', 'g', 'l', 'ml', 'un'];

  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.insumo?.nome);
  late final _quantidade = TextEditingController();
  late final _minimo = TextEditingController(
    text: widget.insumo == null ? '' : formatarQuantidade(widget.insumo!.qtdMinima),
  );
  late String _unidade = widget.insumo?.unidadeMedida ?? 'kg';
  bool _enviando = false;

  bool get _editando => widget.insumo != null;

  @override
  void dispose() {
    _nome.dispose();
    _quantidade.dispose();
    _minimo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final api = ApiClient.instance;
      final minimo = lerNumero(_minimo.text) ?? 0;
      if (_editando) {
        await api.atualizarMateriaPrima(
          widget.insumo!.id,
          nome: _nome.text.trim(),
          unidadeMedida: _unidade,
          qtdMinima: minimo,
        );
      } else {
        await api.cadastrarMateriaPrima(
          nome: _nome.text.trim(),
          unidadeMedida: _unidade,
          qtdAtual: lerNumero(_quantidade.text) ?? 0,
          qtdMinima: minimo,
        );
      }
      if (!mounted) return;
      mostrarMensagem(context, _editando ? 'Insumo atualizado.' : 'Insumo cadastrado.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unidadesDisponiveis = {...unidades, _unidade}.toList();
    return TelaFormulario(
      titulo: _editando ? 'Editar insumo' : 'Novo insumo',
      formKey: _form,
      enviando: _enviando,
      textoBotao: _editando ? 'Salvar alterações' : 'Cadastrar insumo',
      onSalvar: _salvar,
      campos: [
        TextFormField(
          controller: _nome,
          autofocus: !_editando,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nome', hintText: 'Ex.: Queijo mussarela'),
          validator: obrigatorio('Informe o nome'),
        ),
        DropdownButtonFormField<String>(
          initialValue: _unidade,
          decoration: const InputDecoration(labelText: 'Unidade de medida'),
          items: [for (final u in unidadesDisponiveis) DropdownMenuItem(value: u, child: Text(u))],
          onChanged: (v) => setState(() => _unidade = v ?? _unidade),
        ),
        if (!_editando)
          TextFormField(
            controller: _quantidade,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Quantidade inicial', hintText: '0', suffixText: _unidade),
            validator: numeroOpcionalNaoNegativo,
          ),
        TextFormField(
          controller: _minimo,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Estoque mínimo',
            hintText: '0',
            suffixText: _unidade,
            helperText: 'Abaixo ou igual a este valor, o insumo fica em estoque crítico.',
          ),
          validator: numeroOpcionalNaoNegativo,
        ),
      ],
    );
  }
}
