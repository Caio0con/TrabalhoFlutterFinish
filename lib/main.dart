import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:projetoquerinop2/text_input.dart';
import 'package:projetoquerinop2/text_extension.dart';
import 'dao.dart';
import 'task_list.dart';
import 'utils.dart';

//import 'package:sqflite_common_ffi/sqflite_ffi.dart';
void main() {
  // if (!kIsWeb) {
  //   sqfliteFfiInit();
  //   databaseFactory = databaseFactoryFfi;
  // }
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PaginaPrincipal(),
    );
  }
}

class PaginaPrincipal extends StatelessWidget {
  const PaginaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("To Do"),
          backgroundColor: Colors.blue,
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Tarefas"),
              Tab(text: "Histórico"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ListaTodo(),
            HistoricoPage(),
          ],
        ),
      ),
    );
  }
}

class ListaTodo extends StatefulWidget {
  const ListaTodo({super.key});

  @override
  State<StatefulWidget> createState() => _ListaTodo();
}

class _ListaTodo extends State<ListaTodo> {
  List<Map<String, dynamic>> _listaTarefas = [];
  List<Map<String, dynamic>> _tarefasFiltradas = [];
  String _filtroTitulo = '';
  String _filtroPrioridade = 'Todas';
  DateTime? _filtroData;
  final Set<int> _tarefasAnimando = {};
  final Map<int, Color> _corAnimacao = {};

  // No meu pc ele fica piscando, provavelmente pq fica atualizando toda hr -> TODO -> arrumar
  Future<void> _atualizarLista() async {
    final dados = await DataAccessObject.getTarefas();
    final listaEditavel = List<Map<String, dynamic>>.from(dados);
    listaEditavel.sort((a, b) {
      const ordem = {'A': 0, 'M': 1, 'B': 2};
      int cmp = (ordem[a['prioridade']] ?? 3).compareTo(ordem[b['prioridade']] ?? 3);
      if (cmp != 0) return cmp;
      final dataA = DateTime.tryParse(a['data_vencimento'] ?? '') ?? DateTime(2100);
      final dataB = DateTime.tryParse(b['data_vencimento'] ?? '') ?? DateTime(2100);
      return dataA.compareTo(dataB);
    });
    setState(() {
      _listaTarefas = listaEditavel;
      _aplicarFiltro();
    });
  }

  void _aplicarFiltro() {
    setState(() {
      _tarefasFiltradas = _listaTarefas.where((tarefa) {
        final tituloOk = _filtroTitulo.isEmpty ||
            (tarefa['titulo']?.toLowerCase() ?? '').contains(_filtroTitulo.toLowerCase());
        final prioridadeOk = _filtroPrioridade == 'Todas' ||
            (tarefa['prioridade'] == _prioridadeParaChar(_filtroPrioridade));
        final dataOk = _filtroData == null ||
            (tarefa['data_vencimento'] != null &&
             DateTime.tryParse(tarefa['data_vencimento'])?.day == _filtroData!.day &&
             DateTime.tryParse(tarefa['data_vencimento'])?.month == _filtroData!.month &&
             DateTime.tryParse(tarefa['data_vencimento'])?.year == _filtroData!.year);
        return tituloOk && prioridadeOk && dataOk;
      }).toList();
    });
  }

  String _prioridadeParaChar(String prioridade) {
    switch (prioridade) {
      case 'Alta':
        return 'A';
      case 'Baixa':
        return 'B';
      case 'Média':
        return 'M';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _atualizarLista();
  }

  // Métodos CRUD
  Future<void> _excluirTarefa(int id) async {
    setState(() {
      _tarefasAnimando.add(id);
      _corAnimacao[id] = Colors.red.shade200;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    await DataAccessObject.deleteTarefa(id);
    setState(() {
      _tarefasAnimando.remove(id);
      _corAnimacao.remove(id);
    });
    _atualizarLista();
  }

  Future<void> _finalizarTarefa(Map<String, dynamic> item) async {
    setState(() {
      _tarefasAnimando.add(item["id"]);
      _corAnimacao[item["id"]] = Colors.green.shade200;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    await DataAccessObject.updateTarefa(
      item["id"],
      item["prioridade"],
      DateTime.now(),
      DateTime.now(),
      "F",
      item["descricao"],
      item["titulo"],
    );
    setState(() {
      _tarefasAnimando.remove(item["id"]);
      _corAnimacao.remove(item["id"]);
    });
    _atualizarLista();
  }

  void _editarTarefa(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.only(top: 50, left: 30, right: 30),
          child: EditarItem(
            tarefa: item,
            atualizar: _atualizarLista,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Pesquisar por título',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  _filtroTitulo = value;
                  _aplicarFiltro();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _filtroPrioridade,
                      items: const [
                        DropdownMenuItem(value: 'Todas', child: Text('Todas')),
                        DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                        DropdownMenuItem(value: 'Média', child: Text('Média')),
                        DropdownMenuItem(value: 'Baixa', child: Text('Baixa')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _filtroPrioridade = value;
                            _aplicarFiltro();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _filtroData ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        setState(() {
                          _filtroData = picked;
                          _aplicarFiltro();
                        });
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por data',
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        child: Text(
                          _filtroData == null
                              ? 'Todas'
                              : '${_filtroData!.day}/${_filtroData!.month}/${_filtroData!.year}',
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Limpar filtros',
                    onPressed: () {
                      setState(() {
                        _filtroTitulo = '';
                        _filtroPrioridade = 'Todas';
                        _filtroData = null;
                        _aplicarFiltro();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return Container(
                height: 500,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.only(top: 50, left: 30, right: 30),
                child: AdicionarItem(atualizar: _atualizarLista),
              );
            },
          );
        },
        backgroundColor: Colors.blue,
        elevation: 12,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TaskList(
        tasks: _tarefasFiltradas,
        onDelete: _excluirTarefa,
        onEdit: _editarTarefa,
        onTap: _finalizarTarefa,
        tarefasAnimando: _tarefasAnimando,
        corAnimacao: _corAnimacao,
      ),
    );
  }
}

class AdicionarItem extends StatefulWidget {
  final Future<void> Function() atualizar;

  const AdicionarItem({super.key, required this.atualizar});

  @override
  State<StatefulWidget> createState() => _AdicionarItem();
}

class _AdicionarItem extends State<AdicionarItem> {
  String titulo = "";
  String descricao = "";
  DateTime? dataSelecionada;
  String _prioridadeSelecionada = 'Médio';

  String prioridadeParaChar(String prioridade) {
    switch (prioridade) {
      case 'Alto':
        return 'A';
      case 'Baixo':
        return 'B';
      case 'Médio':
      default:
        return 'M';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextInput(
            updateFunction: (s) {
              setState(() {
                titulo = s;
              });
            },
            textLabel: "Titulo",
            maxLines: 1,
          ),
          TextInput(
            updateFunction: (s) {
              setState(() {
                descricao = s;
              });
            },
            textLabel: "Descrição",
            maxLines: null,
          ),
          Container(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dataSelecionada == null
                      ? "Nenhuma data selecionada"
                      : "Data: ${dataSelecionada!.day}/${dataSelecionada!.month}/${dataSelecionada!.year}",
                  style: const TextStyle(fontSize: 16),
                ),
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        dataSelecionada = pickedDate;
                      });
                    }
                  },
                  child: const Text("Selecionar Data"),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _prioridadeSelecionada,
            items: const [
              DropdownMenuItem(value: 'Alto', child: Text('Alto')),
              DropdownMenuItem(value: 'Médio', child: Text('Médio')),
              DropdownMenuItem(value: 'Baixo', child: Text('Baixo')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _prioridadeSelecionada = value;
                });
              }
            },
          ),
          Container(
            padding: const EdgeInsets.only(top: 50),
            child: TextButton(
              onPressed: () async {
                if (titulo.isEmpty || descricao.isEmpty || dataSelecionada == null) {
                  showCenteredNotification(context, "Por favor, preencha todos os campos e selecione uma data.");
                  return;
                }

                await DataAccessObject.createTarefa(
                  prioridadeParaChar(_prioridadeSelecionada),
                  dataSelecionada!,
                  dataSelecionada!,
                  "A",
                  descricao,
                  titulo,
                );
                widget.atualizar();
                showCenteredNotification(context, "Tarefa criada com sucesso!");
                Navigator.pop(context);
              },
              style: ButtonStyle(alignment: Alignment.center),
              child: const Text("Adicionar"),
            ),
          ),
        ],
      ),
    );
  }
}

class EditarItem extends StatefulWidget {
  final Map<String, dynamic> tarefa;
  final Future<void> Function() atualizar;

  const EditarItem({super.key, required this.tarefa, required this.atualizar});

  @override
  State<StatefulWidget> createState() => _EditarItem();
}

class _EditarItem extends State<EditarItem> {
  late TextEditingController tituloController;
  late TextEditingController descricaoController;
  DateTime? dataSelecionada;
  String _prioridadeSelecionada = 'Médio';

  @override
  void initState() {
    super.initState();
    tituloController = TextEditingController(text: widget.tarefa["titulo"]);
    descricaoController = TextEditingController(text: widget.tarefa["descricao"]);
    dataSelecionada = widget.tarefa["data"] ?? DateTime.now();
    switch (widget.tarefa["prioridade"]) {
      case 'A':
        _prioridadeSelecionada = 'Alto';
        break;
      case 'B':
        _prioridadeSelecionada = 'Baixo';
        break;
      case 'M':
      default:
        _prioridadeSelecionada = 'Médio';
        break;
    }
  }

  String prioridadeParaChar(String prioridade) {
    switch (prioridade) {
      case 'Alto':
        return 'A';
      case 'Baixo':
        return 'B';
      case 'Médio':
      default:
        return 'M';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: tituloController,
            decoration: const InputDecoration(labelText: "Titulo"),
            maxLines: 1,
          ),
          TextField(
            controller: descricaoController,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(labelText: "Descrição"),
            maxLines: null,
          ),
          Container(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dataSelecionada == null
                      ? "Nenhuma data selecionada"
                      : "Data: ${dataSelecionada!.day}/${dataSelecionada!.month}/${dataSelecionada!.year}",
                  style: const TextStyle(fontSize: 16),
                ),
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: dataSelecionada ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        dataSelecionada = pickedDate;
                      });
                    }
                  },
                  child: const Text("Selecionar Data"),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _prioridadeSelecionada,
            items: const [
              DropdownMenuItem(value: 'Alto', child: Text('Alto')),
              DropdownMenuItem(value: 'Médio', child: Text('Médio')),
              DropdownMenuItem(value: 'Baixo', child: Text('Baixo')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _prioridadeSelecionada = value;
                });
              }
            },
          ),
          Container(
            padding: const EdgeInsets.only(top: 50),
            child: TextButton(
              onPressed: () async {
                if (tituloController.text.isEmpty ||
                    descricaoController.text.isEmpty ||
                    dataSelecionada == null) {
                  showCenteredNotification(context, "Preencha todos os campos e selecione uma data.");
                  return;
                }

                await DataAccessObject.updateTarefa(
                  widget.tarefa["id"],
                  prioridadeParaChar(_prioridadeSelecionada),
                  dataSelecionada!,
                  dataSelecionada!,
                  "A",
                  descricaoController.text,
                  tituloController.text,
                ).then((_) {
                  widget.atualizar();
                });

                showCenteredNotification(context, "Tarefa editada com sucesso!");
                Navigator.pop(context);
              },
              style: ButtonStyle(alignment: Alignment.center),
              child: const Text("Editar"),
            ),
          ),
        ],
      ),
    );
  }
}

// pagina para o historico:
class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  List<Map<String, dynamic>> _historico = [];

  Future<void> _carregarHistorico() async {
    final dados = await DataAccessObject.getTarefasFinalizadas();
    setState(() {
      _historico = dados;
    });
  }

  Future<void> _excluirHistorico(int id) async {
    await DataAccessObject.deleteTarefa(id);
    _carregarHistorico();
  }

  Future<void> _desfazerTarefa(Map<String, dynamic> item) async {
    await DataAccessObject.updateTarefa(
      item["id"],
      item["prioridade"],
      DateTime.parse(item["data_vencimento"]),
      DateTime.parse(item["data_criacao"]),
      "A",
      item["descricao"],
      item["titulo"],
    );
    _carregarHistorico();
  }


  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _historico.length,
      itemBuilder: (context, index) {
        final item = _historico[index];
        return ListTile(
          title: Text(item['titulo'] ?? ''),
          subtitle: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: parseDescricaoComCheckbox(item['descricao'] ?? ''),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.undo, color: Colors.orange),
                onPressed: () => _desfazerTarefa(item),
                tooltip: "Desfazer",
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _excluirHistorico(item['id']),
                tooltip: "Excluir",
              ),
            ],
          ),
        );
      },
    );
  }
}
