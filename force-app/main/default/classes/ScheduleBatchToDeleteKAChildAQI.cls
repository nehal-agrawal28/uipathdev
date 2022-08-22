/*
* Author: Deepali
* Date: 22nd March 2019
* Description: To have a schedulable class for the BatchToDeleteKAChildAQI batch class*/
global class ScheduleBatchToDeleteKAChildAQI implements Schedulable {
	global void execute(SchedulableContext sc) {
		BatchToDeleteKAChildAQI bcth = new BatchToDeleteKAChildAQI();
		Database.executebatch(bcth);
	}
}