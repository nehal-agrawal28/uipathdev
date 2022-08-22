public class ScheduleBatchToAutoResolveCase_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchToAutoResolveCase_SV bat = new BatchToAutoResolveCase_SV();
    Database.executeBatch(bat);
  }
}