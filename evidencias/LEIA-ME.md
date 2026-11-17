# Evidências — App Cafeteria

Arquivos esperados:

- `formulario.png` — tela de formulário com os campos preenchidos.
- `lista.png` — tela da lista após o consumo ser salvo e sincronizado.

## Geração automatizada (B5)

Com o backend e o PostgreSQL em execução:

```powershell
flutter test test_host/fluxo_sincronizacao_test.dart
```

O teste de integração preenche o formulário, salva, sincroniza com a API real e
gera os dois arquivos nesta pasta. As capturas usam uma viewport de celular
(390 x 844 lógicos) e são salvas em 780 x 1688 pixels.

Observação: o teste usa banco SQLite temporário e remove esse banco ao final.
Os registros sincronizados permanecem no PostgreSQL, pois a API não possui
endpoint de exclusão.

## Alternativa manual (Android)

Com o app aberto no aparelho/emulador e o backend em execução:

```powershell
adb exec-out screencap -p > evidencias\formulario.png
adb exec-out screencap -p > evidencias\lista.png
```

Roteiro:

1. `flutter run` no aparelho Android.
2. Toque em **Novo consumo**.
3. Preencha: **Nome do consumo** `Café com Leite`, **Valor** `12,00`,
   **Identificador** `3`.
4. Gere `evidencias/formulario.png`.
5. Toque em **Salvar consumo**.
6. Aguarde o item aparecer como **Pendente**.
7. Toque em **Sincronizar pendentes (1)** e aguarde o status **Sincronizado**.
8. Gere `evidencias/lista.png`.
