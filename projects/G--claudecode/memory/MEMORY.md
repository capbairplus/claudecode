# Memory Index

- [政治漫畫創意標準](political-cartoon-creative-bar.md) — 評斷創意的兩條硬標準：要有角度、路人要秒懂
- [甲冑 LoRA 專案](armor-lora-project.md) — 用《畫說中國歷代甲冑》掃描頁訓練風格 LoRA：路徑、頁碼偏移+8、15朝代分類、打標容忍決策
- [先查資料再回答](feedback_verify_before_answering.md) — 不確定軟體UI/功能細節時要先搜尋驗證,別憑印象亂猜(3ds Max ActiveShade不支援VRay的教訓)
- [工作區慣例 G:\claudecode](workspace-convention-gclaudecode.md) — 每專案一資料夾,命名 topic_YYYY-MM-DD (ASCII kebab),與 ComfyUI 同槽
- [漂流者 LoRA 專案](drifter-lora-project.md) — 6 角色人物 LoRA;周以諾 Flux v2 完成(成品 v2ep4),其餘 5 角待做
- [檔案連結給純路徑](feedback-file-links-plain-path.md) — 給檔案位置用純 Windows 路徑,別自動開檔;工作目錄落差致連結點不開,可用 .161 ComfyUI 當圖床給 HTTP 連結
- [每張圖存 workflow](feedback-save-workflow-per-image.md) — 生圖時每張都把 ComfyUI 提示詞+workflow JSON 存進 G: 專案 _meta 子夾
- [只做被交代的事](feedback-only-do-what-asked.md) — 不自作主張加額外測試/抓圖/生成,精準照指令走
- [批次生圖流程](feedback-batch-gen-workflow.md) — 一次派遣→單一長等收圖(別多段輪詢)→只在岔路才問,別頻繁跳授權
- [討論式不丟選單](feedback-discuss-not-menu.md) — 決定方向用討論對話,別丟 1/2/3/4 選單給使用者選
- [蘇若冰資料集進度](su-ruobing-dataset-progress.md) — 臉素材 15角度+14表情(Qwen);教訓:表情變體用 Qwen Edit 別用 ChatGPT 瀏覽器(慢又踩雷)
- [ComfyUI .161 啟動與 output2](comfyui-161-launch-output2.md) — 用 cl.vbs 啟動;output2=\\solisnas\solisftp\comfyui\output2(NAS),SYSTEM 碰不到
