public class SchBatToSendCaseInProcessSecRem_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToSendCaseInProcessSecondRem_SV bat = new BatchToSendCaseInProcessSecondRem_SV();
    Database.executeBatch(bat);
  }
}