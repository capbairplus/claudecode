# 素材擴增:從單張/少量圖生出多角度、多表情、多情境

當素材不足(最典型是「只有一張大頭照」),先擴增出多樣圖再訓練。
直接用單張訓練幾乎必定過擬合——模型只會死記那張的角度/光線/表情。

## 選型速查

| 需求 | 首選 | 備註 |
|---|---|---|
| 多表情(笑/怒/閉眼/說話) | **LivePortrait** | 驅動影片/圖搬到靜態照,臉一致性最高 |
| 多角度(正/側/仰/俯) | **Qwen-Image-Edit 多角度 LoRA** 或 **Flux Kontext** | 指令式編輯、保主體,3D 一致性好 |
| 最省事(雲端) | **Gemini 2.5 Flash Image(Nano Banana)** | 角色一致性強,直接產不同角度/表情/場景 |
| 全身多姿勢 | **Animate Anyone / Champ / MimicMotion** | 一張人物圖 + 姿勢序列 |
| 角度自由度最大(可接受品質折損) | **Zero123 / Zero123++ / Wonder3D / TripoSR** | 單圖推新視角,臉部保真有限,當粗胚 |
| 快速換臉 / 貼多樣底圖 | **ReActor / faceswap** | 先備角度表情豐富的底圖,再換上目標臉 |

## 方法分類

### A. 驅動類(單圖 → 大量表情/角度)
- **LivePortrait**:驅動影片/圖把表情、眼神、頭轉搬到靜態照。單圖生多表情神器。
- **AnimateDiff / 影片生成 → 抽格**:讓人物轉頭生成短片再逐格擷取,一次拿多角度;需篩選。

### B. 指令式編輯(直接叫它換角度/表情,保主體)
- **Qwen-Image-Edit「Multiple Angles」LoRA**:`dx8152/Qwen-Edit-2509-Multiple-angles`、
  `fal/Qwen-Image-Edit-2511-Multiple-Angles-LoRA`;2511 版有 96 個攝影機姿勢,訓練含
  Gaussian Splatting,3D 一致性佳。ComfyUI 節點 `jtydhr88/ComfyUI-qwenmultiangle`
  提供 Three.js 互動視窗調角度。強項多角度、表情較弱。
- **Flux.1 Kontext**:照片 + 文字指令(如 "turn head left, smiling")局部編輯保身分。
- **Gemini 2.5 Flash Image(Nano Banana)**:雲端,角色一致性極強。

### C. 控制類(強制指定角度/姿勢)
- **ControlNet(OpenPose / 臉部 landmark / Depth)+ InstantID/IPAdapter 保身分**。
- **InstantID 的 Kps 關鍵點圖**:換不同關鍵點就換角度,最實用。

### D. Talking-head / 肖像動畫(LivePortrait 同類)
- **SadTalker、AniPortrait、Hallo、EMO**:音訊/影片驅動,抽格取表情。

### E. 姿勢驅動人物動畫(全身)
- **Animate Anyone、Champ、MagicPose、MimicMotion**。

### F. 換臉類
- **ReActor / faceswap**:貼到現成多樣底圖,構圖多樣性最好控制;需處理換臉痕跡與光線。

### G. 單圖生新視角(3D / novel view)
- **Zero123 / Zero123++、Wonder3D、TripoSR**;或 **DECA / EG3D / 3DMM** 重建 3D 頭模渲染。

### H. 傳統 img2img(門檻最低,身分易漂移)
- 低 denoise img2img + 角度/表情提示詞、inpaint 只重繪臉/身體、reference-only ControlNet。

## 建議路線圖

多角度 → Qwen 多角度 LoRA 或 Flux Kontext;多表情 → LivePortrait;
兩者混用產出後**人工篩選乾淨**,再進訓練。素材是「風格」而非「人物」時,擴增意義不大,
應改為多方蒐集題材多樣的原作。

## 參考連結
- Qwen Edit 2509 Multi-Angle — https://weirdwonderfulai.art/comfyui/qwen-edit-2509-lora-camera-multi-angle/
- fal Qwen-Image-Edit-2511-Multiple-Angles-LoRA — https://huggingface.co/fal/Qwen-Image-Edit-2511-Multiple-Angles-LoRA
- ComfyUI-qwenmultiangle — https://github.com/jtydhr88/ComfyUI-qwenmultiangle
