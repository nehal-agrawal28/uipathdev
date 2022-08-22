public class ScheduleBatchToSendCaseStrike1Email_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToSendCaseStrike1Email_SV bat = new BatchToSendCaseStrike1Email_SV();
    Database.executeBatch(bat);
  }
}