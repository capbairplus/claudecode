# 範例集

實際程式碼範例,示範四大原則。每個範例展示 LLM 常見的錯誤做法,以及正確做法。

---

## 1. Think Before Coding(先想清楚再動手)

### 範例 1:隱藏的假設

**使用者需求:**「加一個匯出使用者資料的功能」

**❌ LLM 常見做法(亂猜假設)**

```python
def export_users(format='json'):
    """Export all users to a file."""
    users = User.query.all()

    if format == 'json':
        with open('users.json', 'w') as f:
            json.dump([u.to_dict() for u in users], f)
    elif format == 'csv':
        with open('users.csv', 'w') as f:
            writer = csv.DictWriter(f, fieldnames=['id', 'email', 'name'])
            writer.writeheader()
            writer.writerows([u.to_dict() for u in users])

    return f"Exported {len(users)} users"
```

**問題:**
- 假設要匯出「全部」使用者(分頁?隱私考量?都沒問)
- 沒問就假設檔案存放位置
- 沒問就假設要包含哪些欄位
- 沒對照實際資料結構就假設 CSV 欄位名稱

**✅ 正確做法(把假設攤開講)**

```
動手之前,我需要先確認幾件事:

1. **範圍**:匯出全部使用者,還是篩選過的子集合?(涉及隱私)
2. **格式**:你說的「匯出」,是指:
   - 瀏覽器下載檔案?
   - 背景工作 + email 通知?
   - 回傳資料的 API endpoint?
3. **欄位**:要哪些使用者欄位?(有些可能是敏感資訊)
4. **量級**:通常有多少使用者?(影響實作方式)

最簡單的做法:加一個回傳分頁 JSON 的 API endpoint。
如果是要匯出成檔案,需要更多資訊才能決定。

你的偏好是?
```

### 範例 2:多種解讀

**使用者需求:**「讓搜尋變快一點」

**❌ LLM 常見做法(默默挑一個就做)**

```python
# 直接加上 caching、資料庫索引、非同步處理
# 完全沒問使用者在意的「快」到底是哪一種
@lru_cache(maxsize=1000)
async def search(query: str) -> List[Result]:
    # ... 200 行優化程式碼
```

**✅ 正確做法**

```
「讓搜尋變快」可能指:

1. **回應時間變快**(從 500ms 降到 100ms 以下)
   - 加資料庫索引
   - 快取常見查詢
   - 預估工時:2 小時

2. **能處理更多併發搜尋**(吞吐量)
   - 加 async/await
   - 連線池
   - 預估工時:4 小時

3. **感受上比較快**(UX)
   - 先顯示部分結果
   - 漸進式載入
   - 預估工時:3 小時

目前搜尋典型查詢約需 500ms。
你的情境裡哪一項最重要?
```

---

## 2. Simplicity First(簡潔優先)

### 範例 1:過度抽象化

**使用者需求:**「加一個算折扣的函式」

**❌ LLM 常見做法(過度工程化)**

```python
from abc import ABC, abstractmethod
from enum import Enum
from typing import Protocol, Union
from dataclasses import dataclass

class DiscountStrategy(ABC):
    @abstractmethod
    def calculate(self, amount: float) -> float:
        pass

class PercentageDiscount(DiscountStrategy):
    def __init__(self, percentage: float):
        self.percentage = percentage

    def calculate(self, amount: float) -> float:
        return amount * (self.percentage / 100)

class FixedDiscount(DiscountStrategy):
    def __init__(self, fixed_amount: float):
        self.fixed_amount = fixed_amount

    def calculate(self, amount: float) -> float:
        return min(self.fixed_amount, amount)

@dataclass
class DiscountConfig:
    strategy: DiscountStrategy
    min_purchase: float = 0.0
    max_discount: float = float('inf')

class DiscountCalculator:
    def __init__(self, config: DiscountConfig):
        self.config = config

    def apply_discount(self, amount: float) -> float:
        if amount < self.config.min_purchase:
            return 0
        discount = self.config.strategy.calculate(amount)
        return min(discount, self.config.max_discount)

# 光是要用這個簡單計算,呼叫端就要先寫 30 行以上的初始化
```

**✅ 正確做法(簡單)**

```python
def calculate_discount(amount: float, percent: float) -> float:
    """Calculate discount amount. percent should be 0-100."""
    return amount * (percent / 100)

# 用法
discount = calculate_discount(100.0, 10.0)  # 折 10 元
```

**什麼時候該加複雜度:** 只有在真的需要支援多種折扣類型時才加。等那個需求
真的出現了,再回來重構。

### 範例 2:投機性功能

**使用者需求:**「把使用者偏好設定存進資料庫」

**❌ LLM 常見做法(塞進沒人要求的功能)**

```python
class PreferenceManager:
    def __init__(self, db, cache=None, validator=None):
        self.db = db
        self.cache = cache or InMemoryCache()
        self.validator = validator or DefaultValidator()

    def save(self, user_id: int, prefs: dict,
             merge: bool = True,
             validate: bool = True,
             notify: bool = False) -> bool:
        """Save preferences with optional merging, validation, and notifications."""

        if validate:
            errors = self.validator.validate(prefs)
            if errors:
                raise ValidationError(errors)

        existing = self.get(user_id) if merge else {}

        if merge:
            existing.update(prefs)
            prefs = existing

        self.db.execute(
            "UPDATE users SET preferences = ? WHERE id = ?",
            (json.dumps(prefs), user_id)
        )

        if self.cache:
            self.cache.set(f"prefs:{user_id}", prefs)

        if notify:
            self.notify_preference_change(user_id, prefs)

        return True

    def notify_preference_change(self, user_id: int, prefs: dict):
        # 又是 30 行,做一個沒人要求的功能
        pass
```

**✅ 正確做法(只做被要求的事)**

```python
def save_preferences(db, user_id: int, preferences: dict):
    """Save user preferences to database."""
    db.execute(
        "UPDATE users SET preferences = ? WHERE id = ?",
        (json.dumps(preferences), user_id)
    )
```

**之後有需要再加:** Caching(效能真的成問題時)、驗證(真的出現髒資料時)、
merge 邏輯(需求真的出現時)。

---

## 3. Surgical Changes(外科手術式修改)

### 範例 1:順手重構

**使用者需求:**「修一個 bug:email 是空的時候 validator 會壞掉」

**❌ LLM 常見做法(改太多)**

```diff
  def validate_user(user_data):
-     # Check email format
-     if not user_data.get('email'):
+     """Validate user data."""
+     email = user_data.get('email', '').strip()
+
+     # Validate email
+     if not email:
          raise ValueError("Email required")
-
-     # Basic email validation
-     if '@' not in user_data['email']:
+     if '@' not in email or '.' not in email.split('@')[1]:
          raise ValueError("Invalid email")

-     # Check username
-     if not user_data.get('username'):
+     # Validate username
+     username = user_data.get('username', '').strip()
+     if not username:
          raise ValueError("Username required")
+     if len(username) < 3:
+         raise ValueError("Username too short")
+     if not username.isalnum():
+         raise ValueError("Username must be alphanumeric")

      return True
```

**問題:**
- 順便把 email 驗證改得比 bug 修復範圍更大
- 加了沒人要求的 username 驗證
- 改了註解
- 加了 docstring

**✅ 正確做法(外科手術式)**

```diff
  def validate_user(user_data):
      # Check email format
-     if not user_data.get('email'):
+     email = user_data.get('email', '')
+     if not email or not email.strip():
          raise ValueError("Email required")

      # Basic email validation
-     if '@' not in user_data['email']:
+     if '@' not in email:
          raise ValueError("Invalid email")

      # Check username
      if not user_data.get('username'):
          raise ValueError("Username required")

      return True
```

**只改了:** 修復「email 為空」這個具體問題所需的那幾行,沒有更多。

### 範例 2:風格漂移

**使用者需求:**「幫 upload 函式加上 logging」

**❌ LLM 常見做法(整段重新排版)**

```diff
- def upload_file(file_path, destination):
+ def upload_file(file_path: str, destination: str) -> bool:
+     """Upload file to destination with logging."""
+     logger.info(f"Uploading {file_path} to {destination}")
+
      try:
-         with open(file_path, 'rb') as f:
-             data = f.read()
-
-         response = requests.post(destination, files={'file': data})
-
-         if response.status_code == 200:
-             return True
-         else:
-             return False
+         with open(file_path, "rb") as f:
+             data = f.read()
+         response = requests.post(destination, files={"file": data})
+         success = response.status_code == 200
+
+         if success:
+             logger.info(f"Upload successful: {file_path}")
+         else:
+             logger.error(f"Upload failed: {file_path}, status={response.status_code}")
+
+         return success
      except Exception as e:
-         print(f"Error: {e}")
+         logger.exception(f"Upload error for {file_path}: {e}")
          return False
```

**問題:**
- 改了 quote 風格('' 改成 "")
- 加了沒人要求的 type hints
- 加了 docstring
- 整段重新排版
- 改了 boolean 回傳邏輯

**✅ 正確做法(配合既有風格)**

```diff
+ import logging
+
+ logger = logging.getLogger(__name__)
+
  def upload_file(file_path, destination):
+     logger.info(f'Starting upload: {file_path}')
      try:
          with open(file_path, 'rb') as f:
              data = f.read()

          response = requests.post(destination, files={'file': data})

          if response.status_code == 200:
+             logger.info(f'Upload successful: {file_path}')
              return True
          else:
+             logger.error(f'Upload failed: {file_path}, status={response.status_code}')
              return False
      except Exception as e:
-         print(f"Error: {e}")
+         logger.exception(f'Upload error: {file_path}')
          return False
```

**配合了:** 單引號、沒加 type hints、既有的 boolean 寫法、既有的排版風格。

---

## 4. Goal-Driven Execution(目標導向執行)

### 範例 1:模糊 vs 可驗證

**使用者需求:**「把 authentication 系統修好」

**❌ LLM 常見做法(模糊帶過)**

```
我會這樣修 authentication 系統:
1. 檢視程式碼
2. 找出問題
3. 進行改善
4. 測試修改結果

[接著在沒有明確成功標準的情況下就開始改]
```

**✅ 正確做法(可驗證的目標)**

```
要「修好 authentication」,得先定義成功標準。
具體是哪個問題?

如果問題是「使用者改密碼後,舊 session 沒有失效」:

計畫:
1. 寫測試:改密碼 → 驗證舊 session 失效
   驗證方式:測試應該先失敗(重現 bug)

2. 實作:密碼變更時讓 session 失效
   驗證方式:測試通過

3. 檢查邊界情境:多個 active session、併發改密碼
   驗證方式:額外測試也通過

4. 確認沒有 regression:既有 auth 測試仍然全過
   驗證方式:整組測試套件全綠

目前 auth 測試覆蓋率:[顯示覆蓋率]
你實際遇到的 auth 問題具體是什麼?
```

### 範例 2:多步驟並附驗證

**使用者需求:**「幫 API 加上 rate limiting」

**❌ LLM 常見做法(一次全上)**

```python
# 一次 commit 就把 Redis、多種策略、設定系統、監控
# 全部實作進 300 行程式碼裡,完全沒有明確的驗證步驟
```

**✅ 正確做法(分階段 + 每步都驗證)**

```
Rate limiting 計畫:

1. 先做最基本的記憶體內 rate limiting(單一 endpoint)
   驗證方式:
   - 測試:打 100 次請求 → 前 10 次成功,其餘回 429
   - 手動測試:curl 同一個 endpoint 11 次,確認看到 rate limit 錯誤

2. 抽出成 middleware(套用到所有 endpoint)
   驗證方式:
   - 測試:/users 和 /posts 都套用了 rate limit
   - 既有 endpoint 測試仍然全過

3. 加上 Redis backend(支援多台伺服器)
   驗證方式:
   - 測試:app 重啟後 rate limit 狀態仍保留
   - 測試:兩個 app instance 共用同一組 rate limit 計數

4. 加上設定機制(每個 endpoint 可設定不同速率)
   驗證方式:
   - 測試:/search 限 10 次/分鐘,/users 限 100 次/分鐘
   - 設定檔正確解析

每一步都能獨立驗證、獨立部署。
要從第 1 步開始嗎?
```

### 範例 3:先寫測試重現 bug 再修

**使用者需求:**「排序在有重複分數時會壞掉」

**❌ LLM 常見做法(沒重現就直接改)**

```python
# 沒確認 bug 到底怎麼發生,就直接改排序邏輯
def sort_scores(scores):
    return sorted(scores, key=lambda x: (-x['score'], x['name']))
```

**✅ 正確做法(先重現)**

```python
# 1. 先寫一個能重現問題的測試
def test_sort_with_duplicate_scores():
    """Test sorting when multiple items have same score."""
    scores = [
        {'name': 'Alice', 'score': 100},
        {'name': 'Bob', 'score': 100},
        {'name': 'Charlie', 'score': 90},
    ]

    result = sort_scores(scores)

    # bug 所在:分數相同時排序結果不穩定(non-deterministic)
    # 多跑幾次這個測試,結果應該要一致
    assert result[0]['score'] == 100
    assert result[1]['score'] == 100
    assert result[2]['score'] == 90

# 驗證:連續跑 10 次 → 因為排序不穩定而失敗

# 2. 用穩定排序(stable sort)修
def sort_scores(scores):
    """Sort by score descending, then name ascending for ties."""
    return sorted(scores, key=lambda x: (-x['score'], x['name']))

# 驗證:測試每次都穩定通過
```

---

## 反模式總表(Anti-Patterns Summary)

| 原則 | 反模式 | 修正方式 |
|-----------|-------------|-----|
| Think Before Coding | 默默假設檔案格式、欄位、範圍 | 明確列出假設,主動詢問澄清 |
| Simplicity First | 一個折扣計算就套 Strategy pattern | 先寫一個函式就好,等複雜度真的出現再說 |
| Surgical Changes | 修 bug 順便改了 quote 風格、加了 type hints | 只改能修好回報問題的那些行 |
| Goal-Driven | 「我會檢視並改善這段程式碼」 | 「針對 bug X 寫測試 → 讓它通過 → 確認沒有 regression」 |

## 關鍵洞察

那些「過度工程化」的範例並不是明顯錯誤——它們遵循了設計模式和最佳實踐。
問題出在**時機**:在還不需要的時候就加入複雜度,這會:

- 讓程式碼更難理解
- 引入更多 bug
- 花更多時間實作
- 更難測試

「簡單版」的優點:
- 更容易理解
- 實作更快
- 更容易測試
- 等複雜度真的需要時,之後再重構也不遲

**好的程式碼,是簡單地解決今天的問題,而不是提前解決明天可能還不存在的問題。**
