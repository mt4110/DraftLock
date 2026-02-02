# DraftLock — SwiftUI 運用ルール（忘却対策・事故防止）

このドキュメントは DraftLock の SwiftUI 実装で「同じ事故を二度起こさない」ための運用ルール集。

---

## 0. 前提（SwiftUIの現実）

* SwiftUI の View は **値**。`body` は何度でも再評価される。
* 画面は「状態 → 再描画」のサイクルで動く。
* だから **状態の寿命管理** と **副作用の置き場所** が最重要。

---

## 1. ViewModelの寿命ルール（最重要）

### ✅ StateObject / ObservedObject の使い分け

* `@StateObject`：**そのViewがVMを飼う（寿命を持つ）**
* `@ObservedObject`：**外から渡されたVMを見るだけ（寿命を持たない）**

**鉄則**

* “生成する側（Root/親）” が `@StateObject`
* “使う側（子）” は `@ObservedObject`

### ✅ Rootでまとめて飼う

DraftLock では `ContentView`（または `DraftLockApp`）でVMを生成して保持し、子Viewへ渡す。

---

## 2. `body` でやってはいけないこと（副作用禁止）

`body`（または `body` から呼ばれる computed property）では以下をしない：

* `@Published` / `@State` の書き換え
* ファイルI/O（LocalStorageのload/save）
* ネットワーク呼び出し（OpenAI APIなど）
* 重い計算（トークナイズ・集計など）

これをやると、典型的に以下が出る：

* `Publishing changes from within view updates is not allowed...`

---

## 3. 初期ロードの置き場：`.task` を基本にする

起動直後の読み込みや初期化は `onAppear` より `.task` を優先。

**例**

```swift
.task {
  mainVM.bootstrap()
}
```

必要なら “描画サイクルと衝突しない” ために `bootstrap()` の先頭で：

* `await Task.yield()` を使って次のrunloopに逃がす

---

## 4. “Publishing changes...” が出たときの即チェック

この警告はだいたい以下のどれか：

1. `body` 評価中に `@Published` を更新している
2. VMを `body` 内で new している（再描画のたびにVM再生成）
3. `init()` で `@Published` を連打して初回描画と衝突
4. `.onAppear` で同期更新が重なっている

**最優先で疑う箇所**

* Rootで `MainView(vm: MainViewModel())` のように生成していないか
* `init()` 内で `underBar.updateTotals(...)` のように `@Published` を更新していないか

---

## 5. MainActorルール（UI更新の事故防止）

`@Published` を更新するコードは **MainActor上**で行う。

* ViewModelは `@MainActor` にする
* ただし `Task { ... }` 内は油断禁物 → 必要なら `Task { @MainActor in ... }`

---

## 6. 依存注入（StateObject地雷回避）

`@StateObject` 同士を `init()` で依存注入する場合、`self.xxx` を参照してはいけない。

**良い例（ローカル変数で生成→ _xxx に流し込む）**

```swift
init() {
  let promptStudio = PromptStudioViewModel()
  let settings = SettingsViewModel()
  let underBar = UnderBarViewModel()
  let mainVM = MainViewModel(promptStudio: promptStudio, settings: settings, underBar: underBar)

  _promptStudio = StateObject(wrappedValue: promptStudio)
  _settings = StateObject(wrappedValue: settings)
  _underBar = StateObject(wrappedValue: underBar)
  _mainVM = StateObject(wrappedValue: mainVM)
}
```

この形にしておけば、以下の地雷を踏まない：

* `Variable 'self.xxx' used before being initialized`
* `Escaping autoclosure captures mutating 'self' parameter`

---

## 7. “連鎖更新”は控えめに（didSetの使い方）

`didSet` で別の `@Published` を更新すると、更新の波が重なりやすい。

* `didSet` は「軽い同期更新」まで
* 重い処理（見積もりAPI呼び出し）は **debounce + Task** に寄せる

---

## 8. デバッグ手順（最短で犯人を見つける）

1. 警告が出たら、まず Root で VM生成が `@StateObject` になっているか確認
2. `body` / computed property で状態更新していないか確認
3. `.task` / `.onAppear` / `init()` で `@Published` を連打していないか確認
4. 必要なら `await Task.yield()` を挟む

---

## 9. DraftLockの“守るべき形”（最小まとめ）

* VMの生成はRootで `@StateObject` 固定
* 子Viewは `@ObservedObject` で受け取る
* 初期ロードは `.task { vm.bootstrap() }`
* `body` は純粋関数っぽく保つ（副作用は外へ）
* `@Published` 更新はMainActor上で

---
