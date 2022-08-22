public class ScheduleBatchToAutoResolveCase implements System.Schedulable{
	public void execute(System.SchedulableContext sc){
        BatchToAutoResolveCase bat = new BatchToAutoResolveCase();
        Database.executeBatch(bat);
    }
}