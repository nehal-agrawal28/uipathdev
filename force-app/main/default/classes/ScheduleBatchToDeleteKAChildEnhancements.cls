/*
* Author: Deepali
* Date: 22nd March 2019
* Description: To have a schedulable class for the BatchToDeleteKAChildEnhancements batch class*/
global class ScheduleBatchToDeleteKAChildEnhancements implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchToDeleteKAChildEnhancements btch = new BatchToDeleteKAChildEnhancements();
		Database.executebatch(btch);
	}
}