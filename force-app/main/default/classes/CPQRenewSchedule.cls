/**
 * Created by pierre.gousse on 9/11/2019.
 * Schedulable Apex Class to invoke the Batch apex class CPQRenewContractsBatch
 *
 */

global class CPQRenewSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        CPQRenewContractsBatch batchObject = new CPQRenewContractsBatch();
        Id batchId = Database.executeBatch(batchObject, 1);
    }
}