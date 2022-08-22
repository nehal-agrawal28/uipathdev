public class ScheduleBatchInProcessSecondRemML_SV implements System.Schedulable {
  public void execute(System.SchedulableContext sc) {
    BatchInProcessSecondRemML_SV bat = new BatchInProcessSecondRemML_SV();
    Database.executeBatch(bat);
  }
}