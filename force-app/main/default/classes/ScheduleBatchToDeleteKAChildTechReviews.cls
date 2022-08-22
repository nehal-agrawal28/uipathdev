/*
* Author: Deepali
* Date: 22nd March 2019
* Description: To have a schedulable class for the BatchToDeleteKAChildTechReviews batch class*/
global class ScheduleBatchToDeleteKAChildTechReviews implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchToDeleteKAChildTechReviews btch  = new BatchToDeleteKAChildTechReviews();
		Database.executebatch(btch);
	}
}