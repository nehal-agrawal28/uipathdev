public class ScheduleBatchToSendReminderForSurvey implements System.Schedulable{
    public void execute(System.SchedulableContext sc){
        BatchToSendReminderForSurvey  bat = new BatchToSendReminderForSurvey();
        Database.executeBatch(bat);
    }
}