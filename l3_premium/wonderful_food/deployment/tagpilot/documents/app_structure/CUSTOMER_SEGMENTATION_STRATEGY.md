# 客戶分群與策略對應系統

## 系統概覽

TagPilot Premium 實作了一個精密的客戶分群系統，根據客戶的 **ROS (Risk-Opportunity-Stability)** 評分、**IPT (Inter-Purchase Time)** 週期、以及 **生命週期階段** 自動對應到 39 種不同的行銷策略。

## 🎯 核心分群邏輯

### 三維度分群架構

```
維度1: 價值層級 (Value Tier)
├── A: 王者 (高價值客戶)
├── B: 成長 (中價值客戶)
└── C: 潛力 (低價值客戶)

維度2: 活躍度 (Activity Level)  
├── 1: 引擎 (高活躍)
├── 2: 穩健/常規 (中活躍)
└── 3: 休眠/停滯 (低活躍)

維度3: 生命週期 (Lifecycle Stage)
├── N: 新客 (New)
├── C: 成長期 (Cycling)
├── D: 衰退期 (Declining)
├── H: 休眠期 (Hibernating)
└── S: 沉睡期 (Sleeping)
```

### 分群代碼結構
```
[價值][活躍度][生命週期] = 策略代碼
例：A1C = 王者引擎-成長期
```

## 📊 39 種客戶分群定義

### 新客群組 (N) - 6種
| 代碼 | 名稱 | ROS基準 | 特徵描述 |
|------|------|---------|----------|
| A3N | 王者休眠-N | R + S-Median | 高價值新客但互動停滯 |
| B3N | 成長停滯-N | R + S-Low | 中價值新客需激活 |
| C3N | 清倉邊緣-N | R + S-Low | 低價值新客風險高 |
| A1N-A2N | (隱藏) | - | 新客不會有高活躍 |
| B1N-B2N | (隱藏) | - | 新客不會有中高活躍 |
| C1N-C2N | (隱藏) | - | 新客不會有中高活躍 |

### 成長期群組 (C) - 9種
| 代碼 | 名稱 | ROS基準 | 策略重點 |
|------|------|---------|----------|
| A1C | 王者引擎-C | S-High + O | VIP培養+搶先購 |
| A2C | 王者穩健-C | S-High + O | 階梯折扣+新品早鳥 |
| A3C | 王者休眠-C | S-High + R | 深度訪談+專屬客服 |
| B1C | 成長火箭-C | S-High + O | 訂閱制+個性化推薦 |
| B2C | 成長常規-C | S-Median + O | 點數倍數日/會員日 |
| B3C | 成長停滯-C | S-Low + R | 再購提醒+試用包 |
| C1C | 潛力新芽-C | S-Median + O | 升級引導+直播秒殺 |
| C2C | 潛力維持-C | S-Low + O | 補貨提醒+省運方案 |
| C3C | 清倉邊緣-C | S-Low + R | 低成本關懷避免流失 |

### 衰退期群組 (D) - 9種
| 代碼 | 名稱 | ROS基準 | 策略重點 |
|------|------|---------|----------|
| A1D | 王者引擎-D | R + S-Low | 8折VIP喚醒券 |
| A2D | 王者穩健-D | R + S-Low | 致電關懷+NPS調查 |
| A3D | 王者休眠-D | R + S-Low | Win-Back套餐+續會 |
| B1D | 成長火箭-D | R + S-Low | 小遊戲抽獎+回購券 |
| B2D | 成長常規-D | R + S-Low | 品類換血+搭售優惠 |
| B3D | 成長停滯-D | R + S-Low | Push+SMS雙管齊下 |
| C1D | 潛力新芽-D | R + S-Median | 低價快購推薦 |
| C2D | 潛力維持-D | R + S-Low | 簡訊喚醒+滿額贈 |
| C3D | 清倉邊緣-D | R + S-Low | 清庫存閃購一天 |

### 休眠期群組 (H) - 9種
| 代碼 | 名稱 | ROS基準 | 策略重點 |
|------|------|---------|----------|
| A1H | 王者引擎-H | R + S-Low | 專屬客服+差異化補貼 |
| A2H | 王者穩健-H | R + S-Low | 問卷→優惠兩步式 |
| A3H | 王者休眠-H | R + S-Low | VIP喚醒券+滿額升等 |
| B1H | 成長火箭-H | R + S-Low | 會員日兌換券 |
| B2H | 成長常規-H | R + S-Low | 價格敏感試用 |
| B3H | 成長停滯-H | R + S-Low | 再購提醒+小樣包 |
| C1H | 潛力新芽-H | R + S-Low | 爆款低價促銷 |
| C2H | 潛力維持-H | R + S-Low | 免運券+再購提醒 |
| C3H | 清倉邊緣-H | R + S-Low | 月度EDM不再推送 |

### 沉睡期群組 (S) - 9種
| 代碼 | 名稱 | ROS基準 | 策略重點 |
|------|------|---------|----------|
| A1S | 王者引擎-S | R + S-Low | 客服電話+復活禮盒 |
| A2S | 王者穩健-S | R + S-Low | 流失調查+買一送一 |
| A3S | 王者休眠-S | R + S-Low | 客情維繫勿頻促 |
| B1S | 成長火箭-S | R + S-Low | 不定期驚喜包 |
| B2S | 成長常規-S | R + S-Low | 清倉先行名單 |
| B3S | 成長停滯-S | R + S-Low | 定向廣告+SMS |
| C1S | 潛力新芽-S | R + S-Low | 簡訊一次+退訂 |
| C2S | 潛力維持-S | R + S-Low | 只保留月報EDM |
| C3S | 清倉邊緣-S | R + S-Low | 名單除重不再接觸 |

## 🎨 ROS 基準對應

### R (Risk) - 風險導向策略
```r
主要行動：
- R-01: 24h內客服致電關懷 (KPI: 7日回購率)
- R-02: 無風險試用券RFD (KPI: 90日續購率)
- R-03: 交叉銷售/低門檻加購 (KPI: 加購件數)
- R-04: 動態折扣3-7% (KPI: 折扣兌現率)
```

### O (Opportunity) - 機會導向策略
```r
主要行動：
- O-01: 24h豪華組限時加購 (KPI: 24h轉換率)
- O-02: 新品早鳥95折 (KPI: 首發檔期銷售額)
- O-03: 補貨提醒+一鍵下單 (KPI: 單次AOV)
- O-04: 組合包升級10% off (KPI: 升級轉換率)
- O-05: 直播秒殺邀請碼 (KPI: 直播成交率)
- O-06: 好友分享再折5% (KPI: 拉新數)
```

### S (Stability) - 穩定度導向策略
```r
S-High (高穩定度):
- S-H-01: VIP禮/生日禮盒 (KPI: NPS)
- S-H-02: VIP社群+搶先購 (KPI: 90日CLV)
- S-H-03: 深度訪談+專屬客服 (KPI: CSAT)

S-Median (中穩定度):
- S-M-01: 月度電子報+熱銷榜 (KPI: 開信率)
- S-M-02: 季度滿額禮 (KPI: 累計客單)
- S-M-03: 問卷×折扣碼 (KPI: 回收率)

S-Low (低穩定度):
- S-L-01: 週期跟蹤提醒 (KPI: 購買頻率)
- S-L-02: 價格敏感快閃85折 (KPI: 促銷轉換率)
- S-L-03: 訂閱制試用邀請 (KPI: 訂閱開通率)
- S-L-04: 清庫存閃購一天 (KPI: 庫存周轉)
```

## 💡 策略參數設定

### Tempo (T) - 節奏參數
- **T1**: 高頻接觸 (每週2-3次)
- **T2**: 中頻接觸 (每週1次)
- **T3**: 低頻接觸 (每月1-2次)

### Value (V) - 價值參數
- **V1**: 高價值投入 (8%折扣)
- **V2**: 中價值投入 (10%折扣)
- **V3**: 低價值投入 (12-15%折扣)

### Contact Frequency - 接觸次數
- 新客/衰退/休眠/沉睡: 1-2次/月
- 成長期高活躍: 4次/月
- 成長期中活躍: 2次/月
- 成長期低活躍: 1次/月

## 🔄 程式實作流程

### 1. 客戶分群計算
```r
# 在 module_dna_multi_premium.R 中
calculate_ipt_segments_full <- function(dna_data) {
  # IPT分群 (T1/T2/T3)
  t1_cutoff <- ceiling(total_customers * 0.20)  # Top 20%
  t2_cutoff <- ceiling(total_customers * 0.50)  # Top 50%
  
  # 分配segment
  dna_result <- dna_sorted %>%
    mutate(
      ipt_segment = case_when(
        ipt_rank <= t1_cutoff ~ "T1",
        ipt_rank <= t2_cutoff ~ "T2",
        TRUE ~ "T3"
      )
    )
}
```

### 2. 策略對應
```r
# 策略定義函數
get_strategy <- function(grid_position) {
  # 隱藏不合理的新客組合
  hidden_segments <- c("A1N", "A2N", "B1N", "B2N", "C1N", "C2N")
  
  if (grid_position %in% hidden_segments) {
    return(NULL)
  }
  
  # 從39種策略中選擇
  strategies <- list(
    "A3N" = list(
      title = "王者休眠-N",
      icon = "👑",
      action = "48h客服致電+季度滿額禮",
      kpi = "7日回購率"
    ),
    # ... 其他38種策略
  )
  
  return(strategies[[grid_position]])
}
```

### 3. UI呈現
```r
# 生成策略卡片
renderUI({
  # 獲取客戶分群
  grid_position <- paste0(value_level, activity_level, lifecycle_stage)
  
  # 獲取對應策略
  strategy <- get_strategy(grid_position)
  
  # 生成HTML卡片
  HTML(sprintf('
    <div style="border-left: 4px solid %s;">
      <h4>%s %s</h4>
      <p>客戶數: %d | 平均價值: %s</p>
      <p>建議策略: %s</p>
      <p>KPI: %s</p>
    </div>
  ', color, icon, title, count, avg_value, action, kpi))
})
```

## 📈 策略效果追蹤

### KPI 監控體系
| KPI類型 | 計算方式 | 目標值 |
|---------|----------|--------|
| 7日回購率 | 7日內回購客戶/總觸達客戶 | >15% |
| 24h轉換率 | 24h內下單/總曝光 | >3% |
| 90日CLV | 90日內總消費額 | 成長>20% |
| NPS淨推薦值 | 推薦者%-批評者% | >30 |
| 開信率 | 開信數/發信數 | >25% |
| 促銷ROI | 銷售額/行銷成本 | >3.0 |

### A/B 測試框架
```r
# 對照組設定
control_group <- sample_frac(segment_customers, 0.1)  # 10%對照組
test_group <- anti_join(segment_customers, control_group)

# 策略執行
apply_strategy(test_group, strategy_code)
no_action(control_group)

# 效果評估
measure_uplift <- function() {
  test_performance - control_performance
}
```

## 🔍 特殊處理邏輯

### 1. 新客特殊處理
- 新客不會有高活躍度 (隱藏A1N-C2N)
- 重點在首購體驗和二購轉換
- 避免過度促銷影響品牌價值感知

### 2. 高價值客戶保護
- A級客戶優先人工客服
- 避免過度自動化傷害體驗
- 提供差異化專屬服務

### 3. 流失預警機制
- D/H/S階段自動觸發預警
- 分級處理避免資源浪費
- C級客戶採用低成本喚醒

## 🚀 未來優化方向

1. **AI個性化**: 基於個體特徵微調策略
2. **動態閾值**: 根據季節性調整分群邊界
3. **多渠道協同**: 整合LINE/SMS/APP推送
4. **預測模型**: 提前預測生命週期轉換
5. **自動化執行**: 對接MA系統自動觸發

---
**文件版本**: v1.0  
**更新日期**: 2024-08-26  
**維護者**: Claude Code  
**資料來源**: strategy.csv, mapping.csv, module_dna_multi_premium.R