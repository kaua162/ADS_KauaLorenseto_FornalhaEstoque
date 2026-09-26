# App - FornalhaEstoque (Flutter)

Esta pasta vai conter o aplicativo mobile (Flutter). Ele ainda não foi gerado porque
o Flutter SDK precisa rodar na sua máquina (não é possível gerar o projeto Flutter completo
sem o SDK instalado).

## Como criar o projeto Flutter aqui

1. Instale o Flutter SDK: https://docs.flutter.dev/get-started/install
2. Dentro desta pasta `app/`, rode:

```bash
flutter create . 
```

Isso vai gerar toda a estrutura padrão do Flutter (`lib/`, `android/`, `ios/`, `pubspec.yaml`, etc.)
dentro desta mesma pasta, sem sobrescrever este README.

3. Depois de criado, use o arquivo [`lib/main_esqueleto.dart`](lib/main_esqueleto.dart) como
   ponto de partida — copie o conteúdo para `lib/main.dart` gerado pelo Flutter.

## Endpoints que o app vai consumir (ver `api/README.md`)

- `POST /auth/login`
- `GET/POST /materia-prima`
- `POST /materia-prima/<id>/movimentacao`
