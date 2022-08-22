public class SchBatchToSendCaseResolvedRem_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToSendCaseResolvedReminder_SV bat = new BatchToSendCaseResolvedReminder_SV();
    Database.executeBatch(bat);
  }
}