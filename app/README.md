# App - La Fornalha (Flutter)

Aplicativo do vendedor da pizzaria La Fornalha. Consome a API Flask da pasta [`api/`](../api/README.md).

Plataformas: **web** e **Android**. Interface em português do Brasil.

## Pré-requisitos

- Flutter SDK 3.47+ (`flutter --version`)
- API rodando (veja [`api/README.md`](../api/README.md)), por padrão em `http://127.0.0.1:5000`
- Um usuário cadastrado na API (endpoint auxiliar `POST /auth/registrar`)

## Como rodar

```bash
cd app
flutter pub get
```

**No Chrome (web):**

```bash
flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:5000
```

Na web o conteúdo fica limitado a 480px de largura e centralizado, para parecer um celular.

**No emulador Android:** o `127.0.0.1` do emulador é o próprio emulador. Use `10.0.2.2` para chegar ao PC:

```bash
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:5000
```

> Em celular físico, use o IP da máquina na rede (ex.: `http://192.168.0.10:5000`) e suba a
> API com `flask --app run.py run --host 0.0.0.0`.
> Como a API usa `http` (sem TLS), o `AndroidManifest.xml` já declara a permissão `INTERNET` e
> `android:usesCleartextTraffic="true"`. Se um dia a API for para `https`, remova essa linha.

Sem `--dart-define`, o app usa `http://127.0.0.1:5000`.

## Testes e análise

```bash
flutter analyze
flutter test
```

Os testes usam uma API falsa (`MockClient`), então não precisam da API rodando nem mexem no banco.

> **Windows com acento no caminho** (ex.: `C:\Users\Kauã\...`): o `flutter analyze` do Dart
> 3.13 pode falhar com `FormatException: Unexpected end of input`. Contorno: mapear a pasta
> para uma letra de unidade e rodar de lá:
>
> ```bat
> subst W: "C:\Users\Kauã\ADS_KauaLorenseto_FornalhaEstoque"
> cd /d W:\app
> flutter analyze
> subst W: /d
> ```

## Telas

| Aba / tela | O que faz | Endpoints |
|---|---|---|
| Login | Entra com usuário e senha; guarda o `id_usuario` em memória | `POST /auth/login` |
| Insumos | Lista com resumo, filtro Todos/Críticos, barra de nível; toque abre movimentação (entrada/saída), editar e excluir | `GET/POST /materia-prima`, `PUT/DELETE /materia-prima/<id>`, `POST /materia-prima/<id>/movimentacao` |
| Novo/Editar insumo | Nome, unidade, quantidade inicial, mínimo | `POST`/`PUT /materia-prima` |
| Pizzas | Total em estoque, um card por sabor com preço, lote mais antigo e quantidade; toque edita o sabor | `GET /pizza-sabor`, `GET /estoque-pizza/resumo` |
| Novo/Editar sabor | Nome, descrição, preço | `POST/PUT/DELETE /pizza-sabor` |
| Registrar produção | Sabor, quantidade, data opcional | `POST /estoque-pizza/producao` |
| Pedidos | Filtro por status (pela API), cards com mercado, status, data, pizzas e valor | `GET /pedido-revenda?status=` |
| Detalhe do pedido | Itens, total e mudança de status (cancelar devolve o estoque) | `GET /pedido-revenda/<id>`, `PUT /pedido-revenda/<id>/status` |
| Novo pedido | Mercado + stepper por sabor limitado ao disponível; a API dá baixa no estoque (tudo ou nada) | `GET /mercado-parceiro`, `POST /pedido-revenda` |
| Mercados | Busca por nome ou CNPJ/CPF; cards com documento formatado, cidade/UF e telefone | `GET /mercado-parceiro` |
| Detalhe do mercado | Seções Identificação, Contato, Endereço e Observações; Editar, Excluir e os 5 últimos pedidos | `GET /mercado-parceiro/<id>`, `GET /pedido-revenda?id_mercado=`, `DELETE /mercado-parceiro/<id>` |
| Novo/Editar mercado | Todos os campos, com máscara de CNPJ/CPF, telefone e CEP; também usado no "Novo pedido" | `POST`/`PUT /mercado-parceiro` |
| Relatórios | Hoje / 7 dias / Este mês: valor vendido, pedidos, pizzas e barras por sabor | `GET /relatorios/vendas` |

O `ApiClient` também expõe os demais relatórios (`/relatorios/estoque-materia-prima`,
`/relatorios/estoque-pizza`, `/relatorios/movimentacoes-materia-prima`).

> A aba Mercados usa os campos novos de `mercado_parceiro`. Antes de usar, rode a migração
> [`api/migracoes/2026-10-13_mercado_endereco.sql`](../api/migracoes/2026-10-13_mercado_endereco.sql)
> no PostgreSQL (veja o README da API).

## Estrutura

```
lib/
├── main.dart              # MaterialApp, tema, pt-BR, largura máxima na web
├── models/modelos.dart    # classes espelhando o JSON da API
├── services/
│   ├── api_client.dart    # todas as chamadas HTTP + tratamento de erro
│   └── sessao.dart        # usuário logado (em memória)
├── screens/               # uma tela por arquivo
├── theme/app_theme.dart   # cores, fontes (Bricolage Grotesque / DM Sans), raios
├── utils/
│   ├── formatos.dart      # R$ 1.558,00, dd/MM, CNPJ/CPF, telefone, CEP, busca sem acento
│   └── mascaras.dart      # máscaras de digitação (CNPJ/CPF, telefone, CEP)
└── widgets/               # pill de status, barra de nível, chips, estados vazio/erro/carregando
test/                      # formatos, máscaras, ApiClient e telas (com API falsa)
```

## Observações

- **Sessão:** não há token. O usuário fica só em memória; recarregar a página volta para o login.
- **Erros:** mensagens `{"erro": "..."}` da API aparecem num SnackBar; sem conexão aparece
  "Não foi possível conectar ao servidor". Listas mostram carregando, vazio e erro com "Tentar novamente".
- **Fontes:** o `google_fonts` baixa as fontes na primeira execução (precisa de internet).
  Está fixado em `^8.0.0` porque a versão 9 usa o pacote `material_ui`, incompatível com o
  `package:flutter/material.dart` usado no app.
