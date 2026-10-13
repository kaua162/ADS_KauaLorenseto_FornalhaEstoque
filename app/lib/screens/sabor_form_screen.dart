import 'package:flutter/material.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../widgets/formulario.dart';
import '../widgets/mensagens.dart';

/// RF05 - Cadastrar (ou editar/excluir) sabor de pizza congelada.
class SaborFormScreen extends StatefulWidget {
  const SaborFormScreen({super.key, this.sabor});

  final PizzaSabor? sabor;

  @override
  State<SaborFormScreen> createState() => _SaborFormScreenState();
}

class _SaborFormScreenState extends State<SaborFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.sabor?.nome);
  late final _descricao = TextEditingController(text: widget.sabor?.descricao);
  late final _preco = TextEditingController(
    text: widget.sabor == null ? '' : widget.sabor!.precoUnitario.toStringAsFixed(2).replaceAll('.', ','),
  );
  bool _enviando = false;

  bool get _editando => widget.sabor != null;

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _preco.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final api = ApiClient.instance;
      final nome = _nome.text.trim();
      final descricao = _descricao.text.trim().isEmpty ? null : _descricao.text.trim();
      final preco = lerNumero(_preco.text)!;
      if (_editando) {
        await api.atualizarSabor(widget.sabor!.id, nome: nome, descricao: descricao, precoUnitario: preco);
      } else {
        await api.cadastrarSabor(nome: nome, descricao: descricao, precoUnitario: preco);
      }
      if (!mounted) return;
      mostrarMensagem(context, _editando ? 'Sabor atualizado.' : 'Sabor cadastrado.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _excluir() async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir sabor?',
      mensagem: 'Só é possível excluir sabores sem estoque e sem pedidos.',
      textoConfirmar: 'Excluir',
    );
    if (!ok || !mounted) return;
    setState(() => _enviando = true);
    try {
      await ApiClient.instance.removerSabor(widget.sabor!.id);
      if (!mounted) return;
      mostrarMensagem(context, 'Sabor removido.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaFormulario(
      titulo: _editando ? 'Editar sabor' : 'Novo sabor',
      formKey: _form,
      enviando: _enviando,
      textoBotao: _editando ? 'Salvar alterações' : 'Cadastrar sabor',
      onSalvar: _salvar,
      acoes: [
        if (_editando)
          IconButton(
            tooltip: 'Excluir sabor',
            onPressed: _enviando ? null : _excluir,
            icon: const Icon(Icons.delete_outline_rounded, color: Cores.primariaEscura),
          ),
      ],
      campos: [
        TextFormField(
          controller: _nome,
          autofocus: !_editando,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nome do sabor', hintText: 'Ex.: Calabresa'),
          validator: obrigatorio('Informe o nome'),
        ),
        TextFormField(
          controller: _descricao,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
        ),
        TextFormField(
          controller: _preco,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Preço unitário', prefixText: 'R\$ ', hintText: '0,00'),
          validator: (v) {
            final n = lerNumero(v ?? '');
            if (n == null) return 'Informe o preço';
            if (n < 0) return 'O preço não pode ser negativo';
            return null;
          },
        ),
      ],
    );
  }
}
