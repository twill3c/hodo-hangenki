# HARNESS_CHANGELOG.md — ハーネス改訂台帳(hodo-hangenki)

原則: **エージェントがミスをするたびに、そのミスが二度と起きないようハーネスを改良する。**
起票条件: 同一失敗コード累計 2 回(LL-10)、または severity S1(LL-12)。

---

## HC-001

| 項目 | 内容 |
|---|---|
| 起票日 | 2026-08-19 |
| トリガー | `VERIF-FALSE` × 2(loop_001: T-010 が ISO8601 の T/Z を format 指定なしの as.POSIXct でパースし誤検知 / loop_002: T-004 が S=0 点の SE(survfit=NaN、自前=0)まで照合し不一致) |
| 診断 | いずれも「照合の書き方」の失敗。toukei-atlas HC-001 由来の規範(実出力スキーマの検分)は移植済みだったが、**特殊値・端点(未定義域、パーサの方言)** はスキーマを見ただけでは決まらない |
| 改訂 | TEST_SPEC 実行規約に追加: 「照合・パースを含むテストは、書く前に**特殊値の挙動表**(NA/NaN/0/端点/形式方言について両側がどう振る舞うか)を作り、除外規則と共にテスト内コメントへ残す。時刻のパースは必ず format/tz を明示する」 |
| 種別 | test_spec_template |
| SCAFFOLD_VERSION | 1.8.0(プロジェクト局所。toukei-atlas HC-001 と併せてレジストリ還流候補 — 人間の承認待ち) |
| 効果検証 | 以後 5 ループで VERIF-FALSE の再発 0 件なら Closed |
| propagation | hodo-hangenki ✅(本文書 + TEST_SPEC.md)/ レジストリ還流 ⬜ |
| 状態 | Open |
