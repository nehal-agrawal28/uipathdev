public class ScheduleBatchToAutoResolveCaseWE_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToAutoResolveCaseWE_SV bat = new BatchToAutoResolveCaseWE_SV();
    Database.executeBatch(bat);
  }
}