# Cafeteria

App de cadastros de consumos (produtos) de uma cafeteria, feito em Flutter.

Avaliação prática de **Programação para Dispositivos Móveis II**.

- **Aluno:** KAIO LEANDRO RISSATO
- **Entidade:** Consumo (modelado pela classe `Transferencia`)
- **Ícone da entidade:** `Icons.local_cafe`

## Requisitos implementados

- `ListView.builder` + `Card` + `ListTile` para exibir os consumos.
- Componente reutilizável `Editor` controlado por `TextEditingController`.
- Conversão com `double.tryParse` (valor) e `int.tryParse` (identificador).
- Navegação com `Navigator.push` + `MaterialPageRoute`; a tela de formulário
  devolve o objeto com `Navigator.pop(context, transferenciaCriada)`.
- Atualização dinâmica com `Future.delayed` (1 segundo) **antes** do `setState`.
- Valores exibidos no padrão brasileiro: `R$ 12,00`.
- **Somente dados em memória** — sem banco de dados, API ou persistência.

## Estrutura

```
lib/
├── main.dart                              # CafeteriaApp + ThemeData
├── components/
│   └── editor.dart                        # componente Editor
├── models/
│   └── transferencia.dart                 # modelo Transferencia
└── screens/
    └── transferencias/
        ├── lista.dart                     # tela de lista
        └── formulario.dart                # tela de formulário
```

## Como executar

```powershell
flutter pub get
flutter run
```

## Como validar

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

## Evidências

Prints de tela em `evidencias/`. Veja `evidencias/LEIA-ME.md` com o passo a passo.
