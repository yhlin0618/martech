# 斷開所有數據庫連接
dbDisconnect_all()

all_objects <- ls()
objects_to_remove <- setdiff(all_objects, c("autodeinit","autoinit"))

rm(list = objects_to_remove)
rm(list = "objects_to_remove")


# 執行垃圾回收以釋放內存
gc()


# 
# # 檢查 DROPBOX_SYNC 是否存在
# if (exists("DROPBOX_SYNC")) {
#   # 保留 DROPBOX_SYNC
#   current_sync_value <- DROPBOX_SYNC
#   all_objects <- ls()
#   objects_to_remove <- setdiff(all_objects, "DROPBOX_SYNC")
#   
#   if (length(objects_to_remove) > 0) {
#     # 移除除了 DROPBOX_SYNC 以外的所有對象
#     rm(list = objects_to_remove)
#   }
#   
#   message("MP080: Deinitialization completed while preserving DROPBOX_SYNC=", DROPBOX_SYNC)
# } else {
#   # 沒有 DROPBOX_SYNC，移除所有內容
#   rm(list = ls())
#   message("Deinitialization completed with full cleanup")
# }