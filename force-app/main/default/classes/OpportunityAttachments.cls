public with sharing class OpportunityAttachments {
     
   
    
    public List<ContentDocumentLink> contentDocumentLinks {get; set;} 
    
    private final Case c;
    
    public OpportunityAttachments(ApexPages.StandardController stdController) { 
        
        this.c = (Case)stdController.getRecord();
        
        contentDocumentLinks = [SELECT Id, ContentDocumentId ,ContentDocument.title,ContentDocument.LastModifiedDate, LinkedEntityId FROM ContentDocumentLink 
                                WHERE LinkedEntityId IN (SELECT Opportunity__c FROM Case WHERE Id =: c.Id) AND LinkedEntity.Type = 'Opportunity'];
    }
    
       
    public list <ContentDocumentLink> getfile() {
        
        return contentDocumentLinks;
    }
}