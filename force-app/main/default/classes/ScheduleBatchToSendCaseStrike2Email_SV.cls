public class ScheduleBatchToSendCaseStrike2Email_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToSendCaseStrike2Email_SV bat = new BatchToSendCaseStrike2Email_SV();
    Database.executeBatch(bat);
  }
}