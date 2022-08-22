/*
* Author: Deepali
* Date: 15th March 2019
* Description: To cascade delete Knowledge Article child Technical Review which are not modified past n days.*/
global class BatchToDeleteKAChildTechReviews implements Database.Batchable<sObject>{
	public final String query;
	public final Datetime lastndays = System.now() + Integer.valueOf(Label.Days_To_Delete_KA_Child);

	public BatchToDeleteKAChildTechReviews() {
		this.query = 'Select Id from Technical_Review__c where Knowledge_Article__c = null AND LastModifiedDate <= :lastndays';
	}
	/*public BatchToDeleteKAChildTechReviews(String query){
		this.query = query;
	}*/

	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Technical_Review__c> scope){
		System.debug('scope.size' + scope.size());
		System.debug('scope' + scope);

		if(scope != null && scope.size() > 0){
			delete scope;
		}
	}

	global void finish(Database.BatchableContext BC){
		System.debug('BatchToDeleteKAChildTechReviews Executed');

	}
}