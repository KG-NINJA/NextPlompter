# autox

Codex 用の半自動入力スクリプトです。

## 起動

```powershell
powershell -ExecutionPolicy Bypass -File .\keep-codex-going.ps1
```

## 動作

- アクティブな `Codex` ウィンドウを検出します
- `next` をクリップボードに入れます
- 実際の送信はしません
- 最後の `Enter` はユーザーが押します

## 停止

- `q` か `Esc` を押す
- `.\stop.keep-codex-going` ファイルを作る
- `Ctrl+C` で中断する

## 調整

- `-IdleSeconds 120` で送信待ち相当の間隔を変更できます
- `-WindowTitlePattern 'Codex'` で対象ウィンドウ名を変更できます
- `-Message 'next'` でクリップボードに入れる文字を変更できます

## 注意

- このスクリプトは、検出したウィンドウが本当に入力対象かを最終確認しません
- 安全性を上げるなら、貼り付け前にユーザーがウィンドウ状態を確認してください
