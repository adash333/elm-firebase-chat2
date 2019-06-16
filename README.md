# elm-firebase-chat2

このページは、以下の本を写経しながら、Elm0.19 アプリ作成の練習を行っているものです。

[基礎からわかる Elm](https://amzn.to/2YYLeMQ)

以下のコードを写経して、ElmのコードをMain.elmにまとめ、CSSをBulmaを用いて少し改変してみました。

https://github.com/qnoyxu/chat-room

画像は[いらすとや](https://www.irasutoya.com/)のものです。

## DEMO サイト

https://romantic-noyce-862b75.netlify.com/

## インストール方法

ご自身のFirebaseプロジェクトを作成してください。  
（参考：http://i-doctor.sakura.ne.jp/font/?p=37690）

`git clone https://github.com/adash333/elm-firebase-chat2.git`

index.htmlの55行目の`"https://(ご自身のFirebaseのアドレス).firebaseio.com"`のところを、ご自身のものに書き換えてください。

Run `elm install elm/url`  
Run `elm install elm/json`  
Run `elm install elm/random`  
Run `elm install alex-tan/elm-dialog`  
Run `elm install linuss/smooth-scroll` to install all dependencies.

Run `npm install elm-live` 

Run `elm-live src/Main.elm --open -- --output=main.js` to start the development environment.

作成経過は以下に記載しています。

http://i-doctor.sakura.ne.jp/font/?p=38884

## 開発環境

```
Windows 10 Pro
Chrome
VisualStudioCode 1.32.3
git version 2.20.1.windows.1
nvm 1.1.7
node 10.2.0
npm 6.4.1
elm 0.19.0-bugfix6
elm-format 0.8.1

elm-live 3.4.1
elm-test 0.19.0-rev6
```
