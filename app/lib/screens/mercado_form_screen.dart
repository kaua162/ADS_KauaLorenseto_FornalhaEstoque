import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/modelos.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/formatos.dart';
import '../utils/mascaras.dart';
import '../widgets/formulario.dart';
import '../widgets/mensagens.dart';

const ufs = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', //
  'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

final _emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// RF06 - HU07: cadastrar ou editar mercado parceiro. Retorna o mercado salvo.
///
/// Usado na aba Mercados e no cadastro rápido dentro de "Novo pedido".
class MercadoFormScreen extends StatefulWidget {
  const MercadoFormScreen({super.key, this.mercado});

  /// Se informado, edita este mercado.
  final MercadoParceiro? mercado;

  @override
  State<MercadoFormScreen> createState() => _MercadoFormScreenState();
}

class _MercadoFormScreenState extends State<MercadoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final MercadoParceiro? _m = widget.mercado;

  late final _nome = TextEditingController(text: _m?.nome);
  late final _documento = TextEditingController(text: formatarDocumento(_m?.cnpjCpf));
  late final _contato = TextEditingController(text: _m?.nomeContato);
  late final _telefone = TextEditingController(text: formatarTelefone(_m?.telefone));
  late final _email = TextEditingController(text: _m?.email);
  late final _cep = TextEditingController(text: formatarCep(_m?.cep));
  // Sem logradouro novo, aproveita o endereço antigo (texto livre) como ponto de partida.
  late final _logradouro = TextEditingController(text: _m?.logradouro ?? _m?.enderecoAntigo);
  late final _numero = TextEditingController(text: _m?.numero);
  late final _bairro = TextEditingController(text: _m?.bairro);
  late final _cidade = TextEditingController(text: _m?.cidade);
  late final _observacoes = TextEditingController(text: _m?.observacoes);
  late String? _uf = ufs.contains(_m?.uf) ? _m?.uf : null;
  bool _enviando = false;

  bool get _editando => _m != null;

  List<TextEditingController> get _controles => [
    _nome, _documento, _contato, _telefone, _email, _cep, //
    _logradouro, _numero, _bairro, _cidade, _observacoes,
  ];

  @override
  void dispose() {
    for (final c in _controles) {
      c.dispose();
    }
    super.dispose();
  }

  String? _texto(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  String? _digitos(TextEditingController c) {
    final d = somenteDigitos(c.text);
    return d.isEmpty ? null : d;
  }

  Map<String, String?> get _dados => {
    'nome': _nome.text.trim(),
    'cnpj_cpf': somenteDigitos(_documento.text),
    'nome_contato': _texto(_contato),
    'telefone': _digitos(_telefone),
    'email': _texto(_email),
    'cep': _digitos(_cep),
    'logradouro': _texto(_logradouro),
    'numero': _texto(_numero),
    'bairro': _texto(_bairro),
    'cidade': _texto(_cidade),
    'uf': _uf,
    'observacoes': _texto(_observacoes),
  };

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) {
      mostrarMensagem(context, 'Confira os campos destacados.');
      return;
    }
    setState(() => _enviando = true);
    try {
      final api = ApiClient.instance;
      final salvo = _editando ? await api.atualizarMercado(_m!.id, _dados) : await api.cadastrarMercado(_dados);
      if (!mounted) return;
      mostrarMensagem(context, _editando ? 'Mercado atualizado.' : 'Mercado "${salvo.nome}" cadastrado.');
      Navigator.pop(context, salvo);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaFormulario(
      titulo: _editando ? 'Editar mercado' : 'Novo mercado',
      formKey: _form,
      enviando: _enviando,
      textoBotao: _editando ? 'Salvar alterações' : 'Cadastrar mercado',
      onSalvar: _salvar,
      campos: [
        const _Secao('Identificação'),
        TextFormField(
          controller: _nome,
          autofocus: !_editando,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(150)],
          decoration: const InputDecoration(labelText: 'Nome *', helperText: 'Razão social ou nome fantasia'),
          validator: obrigatorio('Informe o nome'),
        ),
        TextFormField(
          controller: _documento,
          keyboardType: TextInputType.number,
          inputFormatters: [MascaraDigitos.documento()],
          decoration: const InputDecoration(labelText: 'CNPJ ou CPF *', hintText: '00.000.000/0000-00'),
          validator: (v) {
            final d = somenteDigitos(v ?? '');
            if (d.isEmpty) return 'Informe o CNPJ ou CPF';
            if (d.length != 11 && d.length != 14) return 'CPF tem 11 dígitos e CNPJ tem 14';
            return null;
          },
        ),
        const _Secao('Contato'),
        TextFormField(
          controller: _contato,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(120)],
          decoration: const InputDecoration(labelText: 'Nome do contato'),
        ),
        TextFormField(
          controller: _telefone,
          keyboardType: TextInputType.phone,
          inputFormatters: [MascaraDigitos.telefone()],
          decoration: const InputDecoration(labelText: 'Telefone', hintText: '(54) 99999-9999'),
          validator: (v) {
            final d = somenteDigitos(v ?? '');
            if (d.isNotEmpty && d.length != 10 && d.length != 11) return 'Informe DDD + número';
            return null;
          },
        ),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          inputFormatters: [LengthLimitingTextInputFormatter(120)],
          decoration: const InputDecoration(labelText: 'E-mail', hintText: 'compras@mercado.com.br'),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isNotEmpty && !_emailValido.hasMatch(t)) return 'E-mail inválido';
            return null;
          },
        ),
        const _Secao('Endereço'),
        TextFormField(
          controller: _cep,
          keyboardType: TextInputType.number,
          inputFormatters: [MascaraDigitos.cep()],
          decoration: const InputDecoration(labelText: 'CEP', hintText: '00000-000'),
          validator: (v) {
            final d = somenteDigitos(v ?? '');
            if (d.isNotEmpty && d.length != 8) return 'O CEP tem 8 dígitos';
            return null;
          },
        ),
        TextFormField(
          controller: _logradouro,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(150)],
          decoration: const InputDecoration(labelText: 'Logradouro', hintText: 'Rua, avenida...'),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: TextFormField(
                controller: _numero,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                decoration: const InputDecoration(labelText: 'Número'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _bairro,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: const InputDecoration(labelText: 'Bairro'),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _cidade,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: const InputDecoration(labelText: 'Cidade'),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 104,
              child: DropdownButtonFormField<String?>(
                initialValue: _uf,
                decoration: const InputDecoration(labelText: 'UF'),
                menuMaxHeight: 320,
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('—')),
                  for (final uf in ufs) DropdownMenuItem<String?>(value: uf, child: Text(uf)),
                ],
                onChanged: (v) => setState(() => _uf = v),
              ),
            ),
          ],
        ),
        const _Secao('Observações'),
        TextFormField(
          controller: _observacoes,
          textCapitalization: TextCapitalization.sentences,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Observações',
            hintText: 'Horário de entrega, forma de pagamento...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao(this.titulo);

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(titulo, style: estiloTitulo(18)),
  );
}
