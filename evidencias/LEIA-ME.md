# Evidências — App Cafeteria

Coloque aqui os dois prints exigidos:

- `formulario.png` — tela de formulário com os campos preenchidos.
- `lista.png` — tela da lista **após** o novo consumo ser salvo.

## Como gerar (com o app rodando no Android)

Com o app aberto no aparelho/emulador, em outro terminal:

```powershell
adb exec-out screencap -p > evidencias\formulario.png
adb exec-out screencap -p > evidencias\lista.png
```

Alternativa em dois passos:

```powershell
adb shell screencap -p /sdcard/tela.png
adb pull /sdcard/tela.png evidencias\formulario.png
```

## Roteiro sugerido

1. `flutter run` no aparelho Android.
2. Toque no botão flutuante **Novo consumo** (ícone de café).
3. Preencha: **Nome do consumo** `Café com Leite`, **Valor** `12,00`,
   **Identificador** `3`.
4. Print da tela preenchida → `evidencias/formulario.png`.
5. Toque em **Salvar consumo**.
6. Aguarde ~1 segundo (o `Future.delayed` segura a inclusão antes do `setState`).
7. Print da lista já com o novo item → `evidencias/lista.png`.
