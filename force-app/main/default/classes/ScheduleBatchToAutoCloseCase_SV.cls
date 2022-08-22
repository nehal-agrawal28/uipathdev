public class ScheduleBatchToAutoCloseCase_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToAutoCloseCase_SV bat = new BatchToAutoCloseCase_SV();
    Database.executeBatch(bat);
  }
}