public class ScheduleBatchInProcessSecondRemML  implements System.Schedulable{
	public void execute(System.SchedulableContext sc){
        BatchInProcessSecondRemML  bat = new BatchInProcessSecondRemML();
        Database.executeBatch(bat);
    }
}