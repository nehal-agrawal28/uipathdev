public class ScheduleBatchToSendCaseResolvedReminder implements System.Schedulable{
	public void execute(System.SchedulableContext sc){
        BatchToSendCaseResolvedReminder  bat = new BatchToSendCaseResolvedReminder();
        Database.executeBatch(bat);
    }
}