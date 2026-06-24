# 更新日誌

> 每次發布新版本時，請在這裡新增一個 `## v<版本號>` 區塊（需與 `plugin.js` 的 `PLUGIN_VERSION` 完全一致），release workflow 會自動把對應區塊放進 GitHub Release 的更新說明。

## v2.3.1
- **Auto-Join**：在 Task / Event 的編輯表單頁面按下 Save，會自動把你加進 Subscribers（Task）／Invitees（Event），如果你還不在清單裡的話；已經在清單裡則不會重複加入，偵測失敗也絕不會擋住存檔。
- **Locate（預覽反查）**：在右側預覽畫面選取文字，編輯器會自動高亮並捲動到對應的原始碼位置，支援 LaTeX 區塊；可用工具列上的「⇄ Locate」開關。
- **Auto Update 開關**：可以關閉「每次打字即時重新渲染預覽」，改用浮動的「↻ Update」按鈕手動更新，長文件編輯更順暢。
- **Minimap 章節導覽**：滑鼠停在右側 minimap 的項目上，若該項目底下有子標題會彈出側邊清單，點擊可直接跳到該子標題；Edit 模式下的標題清單也改為直接讀取編輯器裡的 `=` 語法，順序與層級跟原始碼一致。
- 點擊左上角 Logo 可直接回到 Phabricator 首頁。
- 修正：Minimap 在「顯示較舊的留言」載入新內容後，或 Calendar Event 的預覽因 Phabricator 原生 AJAX 刷新而被替換後，現在會正確跟著更新。
- 語法高光背景的捲動改用 compositor thread 動畫，長文件捲動不再有延遲感。
