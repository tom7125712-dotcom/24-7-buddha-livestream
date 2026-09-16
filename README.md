# 不動如來心咒｜24/7 音樂直播

這是可長期運作的 RTMP 直播專案：使用你提供的封面與音樂，將靜態畫面和循環音訊輸出至 YouTube Live 或任何 RTMP/RTMPS 目的地。

## 重要：真正的 24/7 方式

GitHub-hosted Actions 有最長工作時間、排程延遲與中斷風險，不能保證連續直播。本專案因此把它限制在「部署按鈕」；直播本身必須跑在 VPS、NAS 或持續開機的電腦上，並由 Docker 的 `unless-stopped` 自動重啟。

## 開始直播

1. 在 YouTube Studio 建立直播，取得 RTMP URL 與串流金鑰。
2. 複製設定檔：`cp .env.example .env`。
3. 將 `RTMP_URL` 和 `STREAM_KEY` 填入 `.env`。`.env` 已忽略，請勿提交。
4. 啟動：`docker compose up -d --build`。
5. 看日誌：`docker compose logs -f livestream`。
6. 停止：`docker compose down`。

容器會在 RTMP 斷線或 FFmpeg 異常結束後自動重新連線。健康檢查會監測 FFmpeg 監督程序。

## GitHub 部署

將此資料夾建立為 GitHub repository，並在 `Settings → Secrets and variables → Actions` 加入：

- `RTMP_URL` 與 `STREAM_KEY`，或
- 一個 `FULL_RTMP_URL`。

在一台已安裝 Docker 與 GitHub self-hosted runner 的 Linux 主機上，從 Actions 執行 **Deploy 24/7 livestream**。工作流程會寫入權限為私有的 `.env`，然後啟動或更新容器；串流金鑰不會寫入 repository 或日誌。

## 技術設定

- 1920×1080、30 FPS、H.264/AAC、約 3.5 Mbps 視訊 / 192 kbps 音訊
- 2 秒關鍵影格間隔，適合 RTMP 平台
- 不拉伸封面；比例不同時自動黑邊置中
- 音訊以無限循環方式輸出，並重新取樣以避免時間戳漂移

請確認你擁有或已取得音樂、圖像與上傳／公開直播的必要權利。
