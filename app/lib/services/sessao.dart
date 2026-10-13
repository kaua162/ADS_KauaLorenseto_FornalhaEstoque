import '../models/modelos.dart';

/// Sessão em memória: a API não usa token, só precisamos do id_usuario
/// para enviar no POST /pedido-revenda. Some ao recarregar o app.
abstract final class Sessao {
  static Usuario? usuario;

  static bool get logado => usuario != null;

  static void sair() => usuario = null;
}
