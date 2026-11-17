const express = require('express');
const cors = require('cors');

const healthRoutes = require('./routes/health.routes');
const transferenciasRoutes = require('./routes/transferencias.routes');
const {
  rotaNaoEncontrada,
  tratarErros,
} = require('./middlewares/error.middleware');

const app = express();

app.disable('x-powered-by');
app.use(cors());
app.use(express.json({ limit: '100kb' }));

app.use(healthRoutes);
app.use(transferenciasRoutes);

app.use(rotaNaoEncontrada);
app.use(tratarErros);

module.exports = { app };
