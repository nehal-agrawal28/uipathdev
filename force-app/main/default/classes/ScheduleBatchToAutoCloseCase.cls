public class ScheduleBatchToAutoCloseCase implements System.Schedulable{
	public void execute(System.SchedulableContext sc){
        BatchToAutoCloseCase  bat = new BatchToAutoCloseCase();
        Database.executeBatch(bat);
    }
}