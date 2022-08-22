public class SchBatToSendCaseInProcessFstRem_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToSendCaseInProcessFirstRem_SV bat = new BatchToSendCaseInProcessFirstRem_SV();
    Database.executeBatch(bat);
  }
}