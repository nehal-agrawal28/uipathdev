/*
* Author: Deepali
* Date: 22nd May 2019
* Description: To have a schedulable class for the BatchToDelete30DaysOldCaseAttachment batch class*/
global class ScheduleBatchToDeleteOldCaseAttchmnt implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchToDelete30DaysOldCaseAttachment bcth = new BatchToDelete30DaysOldCaseAttachment();
		Database.executebatch(bcth,100);
	}
}