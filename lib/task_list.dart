import 'package:flutter/material.dart';
import 'package:projetoquerinop2/text_extension.dart';

class TaskList extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final void Function(int) onDelete;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onTap;
  final Set<int> tarefasAnimando;
  final Map<int, Color> corAnimacao;

  const TaskList({
    Key? key,
    required this.tasks,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
    required this.tarefasAnimando,
    required this.corAnimacao,
  }) : super(key: key);

  // Color _getWhichColor(final isAnimando) {
  //   switch (isAnimando) {
  //     case false:
  //       return Colors.red[200]!;
  //     case true:
  //       return Colors.green[200]!;
  //     default:
  //       return Colors.grey[200]!;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text("Nenhuma tarefa adicionada"));
    }
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final item = tasks[index];
        final id = item["id"];
        final isAnimando = tarefasAnimando.contains(id);
        final cardColor = isAnimando ? corAnimacao[id] : Colors.white;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: cardColor,
          child: ListTile(
            leading: Icon(
              Icons.flag,
              color: (() {
                switch (item["prioridade"]) {
                  case 'A':
                    return Colors.redAccent.shade100;
                  case 'M':
                    return Colors.yellow.shade600;
                  case 'B':
                    return Colors.green.shade300;
                  default:
                    return Colors.grey;
                }
              })(),
            ),
            title: Text(item["titulo"]),
            subtitle: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: parseDescricaoComCheckbox(item["descricao"] ?? ''),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black54),
                  onPressed: () => onEdit(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black54),
                  onPressed: () => onDelete(item["id"]),
                ),
              ],
            ),
            onTap: () => onTap(item),
          ),
        );
      },
    );
  }
}