public class ContentDocumentTriggerHandler {

    private boolean isExecuting = false;
    private integer batchSize = 0;
    
    public ContentDocumentTriggerHandler(boolean triggerExecuting, integer size) {
        
        isExecuting = triggerExecuting;
        BatchSize = size;
        
    }
    
    public void onBeforeDelete(List<ContentDocument> oldContentDocuments) {
        
        removeCaseDocId(oldContentDocuments);
        
    }
    
    public void removeCaseDocId(List<ContentDocument> oldContentDocuments) {
        
        List<Id> cdIds = new List<Id>();
        for (ContentDocument cd : oldContentDocuments) {
            cdIds.add(cd.Id);
        }
        List<ContentDocumentLink> toDelete = new List<ContentDocumentLink>();
        String quotePrefix = SBQQ__Quote__c.sobjecttype.getDescribe().getKeyPrefix();
        
        for (ContentDocumentLink cdl : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIds]) {
            // added quotes
            if (((String)cdl.LinkedEntityId).startsWith('500') || ((String)cdl.LinkedEntityId).startsWith(quotePrefix)) {
                toDelete.add(cdl);
            }
        }
        
        if (toDelete.size() > 0)
            delete toDelete;
        
    }
    
}