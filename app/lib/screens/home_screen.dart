import 'package:flutter/material.dart';

import 'insumos_screen.dart';
import 'mercados_screen.dart';
import 'pedidos_screen.dart';
import 'pizzas_screen.dart';
import 'relatorios_screen.dart';

/// Abas principais. Cada aba é recriada ao ser selecionada, para sempre
/// mostrar o estoque atualizado (ex.: depois de um pedido baixar as pizzas).
///
/// A barra inferior é entregue a cada aba, que monta um único Scaffold com ela.
/// Assim o SnackBar empurra o botão flutuante para cima em vez de cobri-lo.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.abaInicial = 0});

  final int abaInicial;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _aba = widget.abaInicial;

  @override
  Widget build(BuildContext context) {
    final barra = NavigationBar(
      selectedIndex: _aba,
      onDestinationSelected: (i) => setState(() => _aba = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: 'Insumos',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_pizza_outlined),
          selectedIcon: Icon(Icons.local_pizza_rounded),
          label: 'Pizzas',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Pedidos',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront_rounded),
          label: 'Mercados',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Relatórios',
        ),
      ],
    );

    return switch (_aba) {
      0 => InsumosScreen(barra: barra),
      1 => PizzasScreen(barra: barra),
      2 => PedidosScreen(barra: barra),
      3 => MercadosScreen(barra: barra),
      _ => RelatoriosScreen(barra: barra),
    };
  }
}
