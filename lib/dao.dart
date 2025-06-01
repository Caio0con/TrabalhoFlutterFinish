import "package:sqflite/sqflite.dart" as sql;

class DataAccessObject {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""
      CREATE TABLE tarefas (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        prioridade CHARACTER(1),
        data_vencimento DATE,
        data_criacao DATE,
        status CHARACTER(1),
        descricao TEXT,
        titulo VARCHAR(255)
        );
    """);
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      "todo.db",
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  static Future<int> createTarefa(
      String prioridade,
      DateTime dataVencimento,
      DateTime dataCriacao,
      String status,
      String descricao,
      String titulo,
      ) async {
    final db = await DataAccessObject.db();
    final dados = {
      "prioridade": prioridade,
      "data_vencimento": dataVencimento.toIso8601String(),
      "data_criacao": dataCriacao.toIso8601String(),
      "status": status,
      "descricao": descricao,
      "titulo": titulo,
    };
    final id = await db.insert("tarefas", dados);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getTarefas() async {
    final db = await DataAccessObject.db();
    return db.query(
      "tarefas",
      where: "status != ?",
      whereArgs: ["F"],
      orderBy: "titulo",
    );
  }

  static Future<List<Map<String, dynamic>>> getTarefa(int id) async {
    final db = await DataAccessObject.db();
    return db.query("tarefas", where: "id = ?", whereArgs: [id]);
  }

  static Future<int> deleteTarefa(int id) async {
    final db = await DataAccessObject.db();
    return await db.delete(
      "tarefas",
      where: "id = ?",
      whereArgs: [id],
    );
  }

  static Future<int> updateTarefa(
      int id,
      String prioridade,
      DateTime dataVencimento,
      DateTime dataCriacao,
      String status,
      String descricao,
      String titulo,
      ) async {
    final db = await DataAccessObject.db();
    final dados = {
      "prioridade": prioridade,
      "data_vencimento": dataVencimento.toIso8601String(),
      "data_criacao": dataCriacao.toIso8601String(),
      "status": status,
      "descricao": descricao,
      "titulo": titulo,
    };
    final resultado = await db.update(
      "tarefas",
      dados,
      where: "id = ?",
      whereArgs: [id],
    );
    return resultado;
  }

  static Future<List<Map<String, dynamic>>> getTarefasFinalizadas() async {
    final db = await DataAccessObject.db();
    return db.query(
      "tarefas",
      where: "status = ?",
      whereArgs: ["F"],
      orderBy: "titulo",
    );
  }
}