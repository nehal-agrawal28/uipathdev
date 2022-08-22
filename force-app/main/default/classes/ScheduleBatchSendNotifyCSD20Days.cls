/**
* @File Name          : ScheduleBatchSendNotifyCSD20Days.cls
* @Description        : SLTECH-7980 If case is in CA for > than 20 days - 
						send email notification to CSDs to that Account Schedulable Batch
* @Author             : 
* @Group              : 
* @Last Modified By   : 
* @Last Modified On   : 9/17/2020.
* @Modification Log   : 
*==============================================================================
* Ver         Date                     Author                 Modification
*==============================================================================
* 1.0    	9/17/2020  						     			Initial Version
**/
public class ScheduleBatchSendNotifyCSD20Days implements System.Schedulable{
    public void execute(System.SchedulableContext sc){
        BatchSendNotifyCSD20Days  Scheduledbat = new BatchSendNotifyCSD20Days();
        Database.executeBatch(Scheduledbat);
    }
}