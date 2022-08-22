public class ScheduleBatchToSendCaseInProcessSecRem implements System.Schedulable{
	public void execute(System.SchedulableContext sc){
        BatchToSendCaseInProcessSecondRem  bat = new BatchToSendCaseInProcessSecondRem();
        Database.executeBatch(bat);
    }
}