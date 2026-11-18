import '../database/transferencia_dao.dart';
import '../models/transferencia.dart';
import '../services/transferencia_api_service.dart';

class ResultadoSincronizacao {
  const ResultadoSincronizacao({
    required this.totalPendentes,
    required this.sincronizados,
    required this.falhas,
    required this.interrompidoPorConexao,
    required this.tempoEsgotado,
  });

  final int totalPendentes;
  final int sincronizados;
  final int falhas;
  final bool interrompidoPorConexao;
  final bool tempoEsgotado;

  int get restantes => totalPendentes - sincronizados;
  bool get tudoSincronizado => restantes == 0;
}

class TransferenciaRepository {
  TransferenciaRepository({
    required TransferenciaDao dao,
    TransferenciaApiService? apiService,
  }) : _dao = dao,
       _apiService = apiService ?? TransferenciaApiService();

  final TransferenciaDao _dao;
  final TransferenciaApiService _apiService;

  Future<List<Transferencia>> listar() {
    return _dao.listar();
  }

  Future<List<Transferencia>> listarPendentes() {
    return _dao.listarPendentes();
  }

  Future<int> contarPendentes() {
    return _dao.contarPendentes();
  }

  Future<Transferencia> cadastrar(Transferencia transferencia) async {
    final Transferencia pendente = transferencia.copyWith(sincronizado: false);
    await _dao.inserir(pendente);
    return pendente;
  }

  Future<ResultadoSincronizacao> sincronizarPendentes() async {
    final List<Transferencia> pendentes = await _dao.listarPendentes();

    int sincronizados = 0;
    int falhas = 0;
    bool interrompidoPorConexao = false;
    bool tempoEsgotado = false;

    for (final Transferencia transferencia in pendentes) {
      try {
        final int remoteId = await _apiService.enviar(transferencia);
        await _dao.marcarSincronizado(transferencia.uuid, remoteId: remoteId);
        sincronizados++;
      } on TransferenciaApiException catch (erro) {
        falhas++;
        if (erro.falhaDeConexao) {
          interrompidoPorConexao = true;
          tempoEsgotado = erro.tempoEsgotado;
          break;
        }
      } catch (erro) {
        falhas++;
        break;
      }
    }

    return ResultadoSincronizacao(
      totalPendentes: pendentes.length,
      sincronizados: sincronizados,
      falhas: falhas,
      interrompidoPorConexao: interrompidoPorConexao,
      tempoEsgotado: tempoEsgotado,
    );
  }

  void dispose() {
    _apiService.dispose();
  }
}
