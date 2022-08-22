public class ScheduleBatchToAutoCloseCaseFromCA_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToAutoCloseCaseFromCA_SV bat = new BatchToAutoCloseCaseFromCA_SV();
    Database.executeBatch(bat);
  }
}