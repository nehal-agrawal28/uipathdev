public class ScheduleBatchInProcessFirstRemML  implements System.Schedulable{
	public void execute(System.SchedulableContext sc){
        BatchInProcessFirstRemML  bat = new BatchInProcessFirstRemML();
        Database.executeBatch(bat);
    }
}