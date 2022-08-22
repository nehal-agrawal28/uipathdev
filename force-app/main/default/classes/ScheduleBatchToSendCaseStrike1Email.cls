public class ScheduleBatchToSendCaseStrike1Email implements System.Schedulable{
	public void execute(System.SchedulableContext sc){
        BatchToSendCaseStrike1Email  bat = new BatchToSendCaseStrike1Email();
        Database.executeBatch(bat);
    }
}