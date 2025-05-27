import 'package:flutter/material.dart';
import 'package:projetoquerinop2/entidades/item_todo.dart';
import 'package:projetoquerinop2/textInput.dart';

import 'dao.dart';

void main() {
  // Inicialização obrigatória do banco de dados para apps desktop (Windows/macOS/Linux).
  // Não é necessária em Android/iOS.
  // Inicializa o banco com sqflite_common_ffi
  // Comentar caso esteja usando o emulador Android/iOS
  //  sqfliteFfiInit();
  // databaseFactory = databaseFactoryFfi;

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
    await DataAccessObject.updateTarefa(item["id"],
        item["prioridade"],
        DateTime.now(),
        DateTime.now(),
        "F",
        item["descricao"],
        item["titulo"]);
    await _atualizarLista();
  }

  Color getColorFromStatus(String status) {
    switch (status) {
      case 'A':
        return Colors.red;
      case 'F':
        return Colors.green;
      default:
        return Colors.black;
    }
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
      body: ListView.builder(
        itemCount: _listaTarefas.length,
        itemBuilder: (context, index) => ListTile(
          leading: Icon(Icons.task),
          title: Text(_listaTarefas[index]["titulo"]),
          subtitle: Text("${_listaTarefas[index]["descricao"]}"),
          tileColor: getColorFromStatus(_listaTarefas[index]["status"]),
          trailing:
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      _excluirTarefa(_listaTarefas[index]["id"]);
                    },
                    icon: Icon(Icons.delete),
                  ),

                ],
              ),

          onTap: () async {
               await _finalizarTarefa(_listaTarefas[index]);
          },
        ),
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
  DateTime? dataSelecionada; // Variável para armazenar a data selecionada

  String _prioridadeSelecionada = 'Médio'; // prioridade padrão

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
    return Column(
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
              if (titulo.isEmpty ||
                  descricao.isEmpty ||
                  dataSelecionada == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Por favor, preencha todos os campos e selecione uma data.",
                    ),
                  ),
                );
                return;
              }

              // print("Título: $titulo");
              // print("Descrição: $descricao");
              // print("Data: ${dataSelecionada!.day}/${dataSelecionada!.month}/${dataSelecionada!.year}");

              // Alguns valores estão fixos.
              // TODO: substituir valores fixos pelas variáveis
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
    );
  }
}
