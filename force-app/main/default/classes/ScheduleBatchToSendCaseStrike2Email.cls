public class ScheduleBatchToSendCaseStrike2Email implements System.Schedulable{
	public void execute(System.SchedulableContext sc){
        BatchToSendCaseStrike2Email  bat = new BatchToSendCaseStrike2Email();
        Database.executeBatch(bat);
    }
}