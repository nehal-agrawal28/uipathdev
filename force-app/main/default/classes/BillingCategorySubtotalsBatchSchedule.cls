global with sharing class BillingCategorySubtotalsBatchSchedule implements Schedulable{

    global void execute(SchedulableContext context) {
        BillingCategorySubtotalsBatch billingCategoryBatch = new BillingCategorySubtotalsBatch ();
        Database.executeBatch(billingCategoryBatch );
    }

}