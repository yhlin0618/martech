# global.R
library(future)
library(future.mirai)
library(promises)

## 1. 依容器 vCPU 自動設定 worker 數
n <- future::availableCores()   # shinyapps.io 自動給 1/2/4
plan(mirai_multisession, workers = n)

## 2. 對於每個 ExtendedTask / future_lapply
##    都直接用 future_promise / future_map 等呼叫即可