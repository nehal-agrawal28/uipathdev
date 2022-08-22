/*
* Author: Deepali
* Date: 21st May 2019
* Description: To delete case attachments from the case that have been closed since last 30 days.*/
global class BatchToDelete30DaysOldCaseAttachment implements Database.Batchable<sObject>{
	public final String query;
	public final Datetime lastndays = System.now() - Integer.valueOf(Label.Days_To_Delete_Case_Attachment);

	public BatchToDelete30DaysOldCaseAttachment() {
		this.query = 'Select Id from Case where Status= \'Closed\' AND ClosedDate >= :lastndays AND (Recordtype.DeveloperName = \'Incident\' OR Recordtype.DeveloperName = \'Academy\' OR Recordtype.DeveloperName = \'Engagement_Request\' OR Recordtype.DeveloperName = \'Japan_Academy\' OR Recordtype.DeveloperName = \'Japan_Engagement_Request\' OR Recordtype.DeveloperName = \'Japan_Incident\' OR Recordtype.DeveloperName = \'Japan_Licensing\' OR Recordtype.DeveloperName = \'Sales_Operation\')';
	}
    
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Case> scope){
		System.debug('scope.size' + scope.size());
		System.debug('scope' + scope);
        
        Set<Id> caseIdSet = new Set<Id>();
        List<Attachment> deleteAttchmentList = new List<Attachment>();
        
        for(Case ca : scope){
            caseIdSet.add(ca.Id);
        }
        if(caseIdSet.size() > 0){
            deleteAttchmentList = [Select Id, ParentId from Attachment where ParentId IN :caseIdSet];
        }
        if(deleteAttchmentList.size() > 0){
            delete deleteAttchmentList;
        }
	}

	global void finish(Database.BatchableContext BC){
		System.debug('BatchToDelete30DaysOldCaseAttachment Executed');

	}
}