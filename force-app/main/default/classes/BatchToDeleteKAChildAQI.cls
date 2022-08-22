/*
* Author: Deepali
* Date: 15th March 2019
* Description: To cascade delete Knowledge Article child AQIs which are not modified past n days.*/
global class BatchToDeleteKAChildAQI implements Database.Batchable<sObject>{
	public final String query;
	public final Datetime lastndays = System.now() + Integer.valueOf(Label.Days_To_Delete_KA_Child);

	public BatchToDeleteKAChildAQI() {
		this.query = 'Select Id from Article_Quality_Index__c where Knowledge__c = null AND LastModifiedDate <= :lastndays';
	}
	/*public BatchToDeleteKAChildAQI(String query){
		this.query = query;
	}*/

	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Article_Quality_Index__c> scope){
		System.debug('scope.size' + scope.size());
		System.debug('scope' + scope);

		if(scope != null && scope.size() > 0){
			delete scope;
		}
	}

	global void finish(Database.BatchableContext BC){
		System.debug('BatchToDeleteKAChildAQI Executed');

	}
}