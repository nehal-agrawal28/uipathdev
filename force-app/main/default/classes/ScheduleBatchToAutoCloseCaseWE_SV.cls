public class ScheduleBatchToAutoCloseCaseWE_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToAutoCloseCaseWE_SV bat = new BatchToAutoCloseCaseWE_SV();
    Database.executeBatch(bat);
  }
}