/**
*
* Author:       Daniel Sarchiz
* Date:         20/11/2017
* Description:  Trigger handler class for Attachment Trigger
*
**/

public class AttachmentTriggerHandler {
    
    private boolean isExecuting = false;
    private integer batchSize = 0;
    
    public AttachmentTriggerHandler(boolean triggerExecuting, integer size) {
        
        isExecuting = triggerExecuting;
        BatchSize = size;
    }
    
    public void onAfterInsert(List<Attachment> newAttachments) {
        
        updateRelatedCasesFile(newAttachments);
    }
    
    private void updateRelatedCasesFile(List<Attachment> newAttachments) {
        
        Set<Id> parentIds = new Set<Id>();
        
        for(Attachment newAttachment : newAttachments) {
            
            parentIds.add(newAttachment.ParentId);
        }
        
        List<dsfs__DocuSign_Status__c> relatedDocuSignStatuses = [SELECT Id, dsfs__Case__c, Quote__c, Billing_Event__c FROM dsfs__DocuSign_Status__c WHERE Id IN : parentIds];
        
        if(relatedDocuSignStatuses.size() > 0) {
            
            Set<Id> caseIds = new Set<Id>();
            // added for quotes - 11/20/2019
            Set<Id> quoteIds = new Set<Id>();
            // added for Billing Events - 10/19/2020
            Set<Id> billingEventIds = new Set<Id>();
            
            for(dsfs__DocuSign_Status__c relatedDocuSignStatus : relatedDocuSignStatuses) {
                
                caseIds.add(relatedDocuSignStatus.dsfs__Case__c);
                // added for quotes - 11/20/2019
                quoteIds.add(relatedDocuSignStatus.Quote__c);
                // added for Billing Events - 10/19/2020
                billingEventIds.add(relatedDocuSignStatus.Billing_Event__c);
            }

            Map<Id, Case> relatedCasesMap = new Map<Id, Case>([SELECT Id FROM Case WHERE Id IN : caseIds AND (RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_1 OR RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_4)]);
            // added for quotes - 11/20/2019
            Map<Id, SBQQ__Quote__c> relatedQuotesMap = new Map<Id, SBQQ__Quote__c>([SELECT Id FROM SBQQ__Quote__c WHERE Id IN : quoteIds]);
            // added for Billing Events - 10/19/2020
            Map<Id, pse__Billing_Event__c> relatedBillingEventsMap = new Map<Id, pse__Billing_Event__c>([SELECT Id FROM pse__Billing_Event__c WHERE Id IN : billingEventIds]);

            if(relatedCasesMap.size() > 0 || relatedQuotesMap.size() > 0 || relatedBillingEventsMap.size() > 0) {
                // change for quotes - 11/20/2019
                // change for Billing Events - 10/19/2020
                List<ContentDocumentLink> relatedContentDocumentLinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : relatedCasesMap.keySet() OR LinkedEntityId IN : relatedQuotesMap.keySet()
                                                                            OR LinkedEntityId IN : relatedBillingEventsMap.keySet()];
                System.debug('RelatedContentDocumentLinks list size is: ' + relatedContentDocumentLinks.size());
                
                if(relatedContentDocumentLinks.size() > 0) {
                    
                    Map<Id, ContentDocumentLink> caseToContentDocumentLinkMap = new Map<Id, ContentDocumentLink>();
                    
                    for(ContentDocumentLink relatedContentDocumentLink : relatedContentDocumentLinks) {
                        
                        caseToContentDocumentLinkMap.put(relatedContentDocumentLink.LinkedEntityId, relatedContentDocumentLink);
                    }
                    List<ContentVersion> newContentVersions = new List<ContentVersion>();
                    
                    for(Attachment newAttachment : newAttachments) {
                        
                        for(dsfs__DocuSign_Status__c relatedDocuSignStatus : relatedDocuSignStatuses) {
                            
                            ContentDocumentLink relatedContentDocumentLink;
                            
                            if(String.isNotBlank(relatedDocuSignStatus.dsfs__Case__c)) {
                                
                                relatedContentDocumentLink = caseToContentDocumentLinkMap.get(relatedDocuSignStatus.dsfs__Case__c);
                            }
                            // added for quotes - 11/20/2019
                            if(String.isNotBlank(relatedDocuSignStatus.Quote__c)) {
                                
                                relatedContentDocumentLink = caseToContentDocumentLinkMap.get(relatedDocuSignStatus.Quote__c);
                            }
                            // added for Billing Event - 10/19/2020
                            if(String.isNotBlank(relatedDocuSignStatus.Billing_Event__c)) {
                                relatedContentDocumentLink = caseToContentDocumentLinkMap.get(relatedDocuSignStatus.Billing_Event__c);
                            }
                            
                            if(relatedContentDocumentLink != null) {
                                if(newAttachment.ParentId == relatedDocuSignStatus.Id) {
                                    
                                    ContentVersion newContentVersion = new ContentVersion();
                                    
                                    newContentVersion.ContentDocumentId = relatedContentDocumentLink.ContentDocumentId;
                                    newContentVersion.versionData = newAttachment.body;
                                    newContentVersion.ContentLocation = 'S';
                                    newContentVersion.Title = newAttachment.Name;
                                    newContentVersion.PathOnClient = newAttachment.Name;
                                    
                                    newContentVersions.add(newContentVersion);
                                }
                            }
                        }
                    }
                    if(newContentVersions.size() > 0) {
                        
                        insert newContentVersions;
                    }
                }
            }
        }
    }
}