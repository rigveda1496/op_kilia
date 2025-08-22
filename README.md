# Total War WARHAMMER III MOD

Total War WARHAMMER III用のニューロード（キャラクター）追加MOD。アビリティ、視覚効果、カスタムモデルが特徴です。

## 機能

###  カスタムアビリティ
-  ドラゴン召喚（召喚魔法） クールダウン付きでスタードラゴンを召喚
-  範囲回復（回復魔法） 木の成長視覚効果付き回復アビリティ
-  爆発攻撃 カスタム視覚効果付き範囲ダメージアビリティ
-  時間操作 バフ・デバフの時間操作系アビリティ
-  ドラゴン変身 変身機能アビリティ
-  即時戦闘勝利　チート・デバック系

###  カスタムキャラクター
- Kilia 独自の外見を持つ独立カスタムロード
- バニラキャラクターに影響を与えない

##  技術実装

### データ
```
├── TSVデータベース（59種類）
├── 3Dモデル統合（.rigid_model_v2, .wsmodel）
├── マテリアル（XMLベース）
├── VFX（Composite Scene .cscファイル）
└── アセット管理（RPFM）
```

### 実装した主要システム

#### 1. ドラゴン召喚システム
使用ファイル
- `main_units_tables.tsv`
- `land_units_tables`
- `agent_recruitment_categories_tables`
- `agent_subtypes_tables`
- `unit_special_abilities_tables.tsv`
- `special_ability_phases_tables.tsv`
- `special_ability_to_special_ability_phase_junctions_tables.tsv`
- `land_units_to_unit_abilities_junctions_tables.tsv`

機能
-  地面ターゲット指定召喚
-  1戦闘1000回、クールダウン無し
-  VFX（光柱 + 嵐エフェクト）
-  マナコストなし（呪文ではなくアビリティ）

#### 2. 範囲回復と視覚効果
複雑なVFX実装
- 視覚効果
- 7つの相互接続されたデータベーステーブル
- カスタムコンポジットシーン統合
- 重要発見 `composite_scene_group_on_active` が木の生成に重要

変更ファイル
- `unit_abilities_tables.tsv`
- `area_of_effect_displays_tables.tsv`
- `battle_vortexs_tables.tsv`
- `composite_scene_files_tables.tsv`
- `special_ability_phases_tables.tsv`

#### 3. カスタムキャラクターモデル統合
Kiliaキャラクター実装
- アイアンドラゴンモデルを使用した独立キャラクター
- 完全なデータベース統合
- マテリアル・テクスチャパス管理
- 元のZhao Mingキャラクターへの影響ゼロ

ファイル構造
```
variantmeshes
└── variantmeshdefinitions
    └── kilia.variantmeshdefinition
```

##  解決した開発課題

### 1. CTD（クラッシュ）問題
問題 データベース変更後のゲームクラッシュ
根本原因 エンティティ名の不一致（`kilia_entity` と `kilia_variant`）
解決方法 land_unitとbuttle_entityテーブル内のカラムをkilia_entityに統一

### 2. アビリティ灰色表示問題
問題 実装したアビリティが使用不可状態で表示
根本原因 複数テーブルの設定値不整合
解決方法 
- `affects_allies false → true`
- `target_self false → true`
- バニラ準拠

### 3. VFXの複雑さ
問題 木の生成エフェクトが表示されない
根本原因 `composite_scene_group_on_active` 設定の欠如
解決方法 正しいカラム設定でデバック&テスト

##  使い方(公開は無し)

1. op_lord_kilia.packを Total War WARHAMMER III の `data` フォルダに展開
2. 公式または非公式MODマネージャーでMODを有効化
4. キャンペーンモードまたはバトルモードを開始してkiliaを確認

##  開発ツール

- RPFM (Rusted PackFile Manager) メイン MOD 開発ツール&データベーステーブル管理
- visualstudio & notepad++ XML&luaファイル編集

### 設計
- モジュラー性 各アビリティシステムは独立して実装可能
- 互換性 バニラゲームシステムとの競合ゼロ
- 保守性 異なる機能間の明確な分離

### 重要な学習：複雑さよりもシンプルさ
- TSVテーブルのみの実装がLUAスクリプトよりも安定
- 直接データベース参照が多くの互換性問題を解決
- バニラ設定分析 & 他者MODを解析し実装

## 技術統計

- 変更したデータベーステーブル 59種類のテーブル
- 実装したカスタムアビリティ 6つの主要システム
- 実装したscriptファイル  4つのluaファイル
- 統合した3Dモデル ２つのキャラクターモデル
- 作成したエフェクト 1つの複雑な視覚効果実装
- 開発期間 [2ヶ月]

##  学び

- 高度なMOD開発技術の学習
- ゲームデータベースアーキテクチャの理解
- カスタム視覚効果の実装
- キャラクターモデル統合手法

![画像の説明](/スクリーンショット.png)

##  動作要件

- Total War WARHAMMER III
- 他のMODは不要
- 他のほとんどのMODと互換性あり

##  既知の問題
- ステータス画面のキャラクターの見た目が小さい

##  ライセンス

このMODはポートフォリオ用に作成されています。全てのアセットはそれぞれの所有者に帰属します。
- Creative Assembly　
- SEGA
- https://steamcommunity.com/sharedfiles/filedetails/?id=2826725184&searchtext=OP+legendary+lord
- https://steamcommunity.com/sharedfiles/filedetails/?id=3007344936&searchtext=BR
- https://steamcommunity.com/sharedfiles/filedetails/?id=2790754811&searchtext=teleport
- https://steamcommunity.com/sharedfiles/filedetails/?id=2988056319&searchtext=dragon

##  バージョン履歴

### v1.0.0 (現在)

---
