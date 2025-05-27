class Itemtodo {
  String titulo;
  String descricao;
  DateTime dataCriacao = DateTime.now();
  String Prioridade = 'Baixa';
  String status;
  Itemtodo(
      {required this.titulo,
        required this.descricao,
        this.Prioridade = 'Baixa',
        this.status = "A"
      }) {
    dataCriacao = DateTime.now();
  }
}
