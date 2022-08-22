public with sharing class AccountAttachments {
    
    public List<ContentDocumentLink> contentDocumentLinks {get; set;} 
    
    private final Case c;
    
    public AccountAttachments(ApexPages.StandardController stdController) { 
        
        this.c = (Case)stdController.getRecord();
        
        contentDocumentLinks = [SELECT Id, ContentDocumentId ,ContentDocument.title,ContentDocument.LastModifiedDate, LinkedEntityId FROM ContentDocumentLink 
                                WHERE LinkedEntityId IN (SELECT AccountId FROM Case WHERE Id =: c.Id) AND LinkedEntity.Type = 'Account'];
    }
    
    // Nu prea imi dau seama de ce ai nevoie de constructorul asta
    public AccountAttachments() {
        
        contentDocumentLinks = [SELECT Id, ContentDocumentId ,ContentDocument.title,ContentDocument.LastModifiedDate, LinkedEntityId FROM ContentDocumentLink 
                                WHERE LinkedEntityId IN ( SELECT AccountId FROM Case) AND LinkedEntity.Type='Account']; 
    }
    
    public list <ContentDocumentLink> getfile() {
        
        return contentDocumentLinks;
    }
}