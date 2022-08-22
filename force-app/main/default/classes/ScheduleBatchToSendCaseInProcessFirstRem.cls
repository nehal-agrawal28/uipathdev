public class ScheduleBatchToSendCaseInProcessFirstRem implements System.Schedulable{
	public void execute(System.SchedulableContext sc){
        BatchToSendCaseInProcessFirstRem  bat = new BatchToSendCaseInProcessFirstRem();
        Database.executeBatch(bat);
    }
}