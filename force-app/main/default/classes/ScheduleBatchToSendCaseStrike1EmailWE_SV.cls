public class ScheduleBatchToSendCaseStrike1EmailWE_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToSendCaseStrike1EmailWE_SV bat = new BatchToSendCaseStrike1EmailWE_SV();
    Database.executeBatch(bat);
  }
}