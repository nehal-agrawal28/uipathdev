public interface IRipReplaceSync_SL {
  void createAsyncTasks(List<SObject> records);
  void syncCancelledRecordsWithReplacementRecord(List<SObject> records, Map<Id, SObject> existingRecords);
  void work();
  void init(List<Id> parentRecordIds, Id initiatingUserId, String initiatingUserTheme);
}