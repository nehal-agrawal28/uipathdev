/*
* Author: Deepali
* Date: 15th March 2019
* Description: To cascade delete Knowledge Article child Knowledge Enhancement which are not modified past n days.*/
global class BatchToDeleteKAChildEnhancements implements Database.Batchable<sObject>{
	public final String query;
	public final Datetime lastndays = System.now() + Integer.valueOf(Label.Days_To_Delete_KA_Child);

	public BatchToDeleteKAChildEnhancements() {
		this.query = 'Select Id from Knowledge_Enhancement__c where Article__c = null AND LastModifiedDate <= :lastndays';
	}
	/*public BatchToDeleteKAChildEnhancements(String query){
		this.query = query;
	}*/

	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Knowledge_Enhancement__c> scope){
		System.debug('scope.size' + scope.size());
		System.debug('scope' + scope);

		if(scope != null && scope.size() > 0){
			delete scope;
		}
	}

	global void finish(Database.BatchableContext BC){
		System.debug('BatchToDeleteKAChildEnhancements Executed');

	}
}