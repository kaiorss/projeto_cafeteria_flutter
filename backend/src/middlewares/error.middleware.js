function rotaNaoEncontrada(req, res) {
  res.status(404).json({ erro: 'Rota não encontrada.' });
}

function tratarErros(erro, req, res, next) {
  if (res.headersSent) {
    return next(erro);
  }

  if (erro.type === 'entity.parse.failed') {
    return res.status(400).json({ erro: 'JSON inválido.' });
  }

  if (erro.type === 'entity.too.large') {
    return res
      .status(413)
      .json({ erro: 'Corpo da requisição muito grande.' });
  }

  const status = Number.isInteger(erro.status) ? erro.status : 500;

  if (status >= 500) {
    console.error('[api] Erro não tratado:', erro);
  }

  return res.status(status).json({
    erro:
      status >= 500 ? 'Erro interno do servidor.' : erro.message,
  });
}

module.exports = { rotaNaoEncontrada, tratarErros };
