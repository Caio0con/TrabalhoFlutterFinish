import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:projetoquerinop2/textInput.dart';
import 'dao.dart';
import 'task_list.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  if (!kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ListaTodo(),
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

  Future<void> _atualizarLista() async {
    final dados = await DataAccessObject.getTarefas();
    print("Tarefas recuperadas: ${dados.length}");
    setState(() {
      _listaTarefas = dados;
    });
  }

  @override
  void initState() {
    super.initState();
    _atualizarLista();
  }

  // Métodos CRUD
  Future<void> _excluirTarefa(int id) async {
    await DataAccessObject.deleteTarefa(id);
    _atualizarLista();
  }

  Future<void> _finalizarTarefa(Map<String, dynamic> item) async {
    await DataAccessObject.updateTarefa(
      item["id"],
      item["prioridade"],
      DateTime.now(),
      DateTime.now(),
      "F",
      item["descricao"],
      item["titulo"],
    );
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
      appBar: AppBar(
        title: const Text("To Do"),
        backgroundColor: Colors.blue,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: TaskList(
        tasks: _listaTarefas,
        onDelete: _excluirTarefa,
        onEdit: _editarTarefa,
        onTap: _finalizarTarefa,
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
          ),
          TextInput(
            updateFunction: (s) {
              setState(() {
                descricao = s;
              });
            },
            textLabel: "Descrição",
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
                if (titulo.isEmpty || descricao.isEmpty || dataSelecionada == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Por favor, preencha todos os campos e selecione uma data."),
                    ),
                  );
                  return;
                }

                DataAccessObject.createTarefa(
                  prioridadeParaChar(_prioridadeSelecionada),
                  dataSelecionada!,
                  dataSelecionada!,
                  "A",
                  descricao,
                  titulo,
                ).then((a) {
                  widget.atualizar();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tarefa criada com sucesso!")),
                );
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
          ),
          TextField(
            controller: descricaoController,
            decoration: const InputDecoration(labelText: "Descrição"),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Preencha todos os campos e selecione uma data."),
                    ),
                  );
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

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Tarefa editada com sucesso!")),
                );
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
