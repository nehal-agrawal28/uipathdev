public class ScheduleBatchToAutoCloseCaseFromCA implements System.Schedulable{
	public void execute(System.SchedulableContext sc){
        BatchToAutoCloseCaseFromCA  bat = new BatchToAutoCloseCaseFromCA();
        Database.executeBatch(bat);
    }
}