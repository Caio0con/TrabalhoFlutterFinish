import 'package:flutter/material.dart';

class TaskList extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final void Function(int) onDelete;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onTap;

  const TaskList({
    Key? key,
    required this.tasks,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  }) : super(key: key);

  // Color _getColorFromStatus(String status) {
  //   switch (status) {
  //     case 'A':
  //       return Colors.red[200]!;
  //     case 'F':
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
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          // color: _getColorFromStatus(item["status"]),
          child: ListTile(
            leading: const Icon(Icons.task),
            title: Text(item["titulo"]),
            subtitle: Text(item["descricao"]),
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