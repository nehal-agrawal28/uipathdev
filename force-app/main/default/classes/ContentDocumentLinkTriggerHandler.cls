/**
*
* Author:       Daniel Sarchiz
* Date:         20/11/2017
* Description:  Trigger handler class for Content Document Link
*
**/

public class ContentDocumentLinkTriggerHandler {
    
    private boolean isExecuting = false;
    private integer batchSize = 0;
    
    public ContentDocumentLinkTriggerHandler(boolean triggerExecuting, integer size) {
        
        isExecuting = triggerExecuting;
        BatchSize = size;
    }
    
    public void onBeforeInsert(List<ContentDocumentLink> newContentDocumentLinks) {
        
        updateShareTypeToInherit(newContentDocumentLinks);
    }
    
    public void onAfterInsert(List<ContentDocumentLink> newContentDocumentLinks) {
        
        populateDocumentId(newContentDocumentLinks);
        createNewContentDocumentLinks(newContentDocumentLinks);
    }
    
    public void onAfterDelete(List<ContentDocumentLink> oldContentDocumentLinks) {
        
        populateDocumentId(oldContentDocumentLinks);
    }
    
    // Business Logic
    
    private void updateShareTypeToInherit(List<ContentDocumentLink> newContentDocumentLinks) {
        
        Set<Id> relatedEntityIds = new Set<Id>();
        Set<Id> relatedEntityQuoteIds = new Set<Id>();
        Set<Id> relatedEntityBillingEventIds = new Set<Id>();
        String quotePrefix = SBQQ__Quote__c.sobjecttype.getDescribe().getKeyPrefix();
        String billingEventPrefix = pse__Billing_Event__c.SObjectType.getDescribe().getKeyPrefix();

        for(ContentDocumentLink documentLink : newContentDocumentLinks) {
            if(((String)documentLink.LinkedEntityId).startsWith('500'))
                relatedEntityIds.add(documentLink.LinkedEntityId);
            if( ((String)documentLink.LinkedEntityId).startsWith(quotePrefix)) 
                relatedEntityQuoteIds.add(documentLink.LinkedEntityId);
            if(((String)documentLink.LinkedEntityId).startsWith(billingEventPrefix)){
                relatedEntityBillingEventIds.add(documentLink.LinkedEntityId);
            }
        }
        // existing code for Cases
        if(relatedEntityIds.size() > 0) {

            Map<Id, Case> relatedCasesMap = new Map<Id, Case>([SELECT Id, Document_Id__c FROM Case WHERE Id IN : relatedEntityIds AND (RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_1 OR RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_4)]);
            
            if(relatedCasesMap.size() > 0) {
                
                for(ContentDocumentLink documentLink : newContentDocumentLinks) {
                    
                    if(relatedCasesMap.containsKey(documentLink.LinkedEntityId)) {
                        
                        documentLink.ShareType = 'I';
                    }
                }
            }
        }
        // added code for Quotes
        if(relatedEntityQuoteIds.size() > 0) {
            
            Map<Id, SBQQ__Quote__c> relatedQuoteMap = new Map<Id, SBQQ__Quote__c>([SELECT Id, Document_ID__c FROM SBQQ__Quote__c WHERE Id IN : relatedEntityQuoteIds]);
            
            if(relatedQuoteMap.size() > 0) {
                
                for(ContentDocumentLink documentLink : newContentDocumentLinks) {
                    
                    if(relatedQuoteMap.containsKey(documentLink.LinkedEntityId)) {
                        
                        documentLink.ShareType = 'I';
                    }
                }
            }
        }
        // added code for Billing Events

        if(relatedEntityBillingEventIds.size() > 0) {

            Map<Id, pse__Billing_Event__c> relatedProjectMap = new Map<Id, pse__Billing_Event__c>([SELECT Id FROM pse__Billing_Event__c WHERE Id IN : relatedEntityBillingEventIds]);

            if(relatedProjectMap.size() > 0) {

                for(ContentDocumentLink documentLink : newContentDocumentLinks) {

                    if(relatedProjectMap.containsKey(documentLink.LinkedEntityId)) {

                        documentLink.ShareType = 'I';
                    }
                }
            }
        }
    }
    
    private void populateDocumentId(List<ContentDocumentLink> contentDocumentLinks) {
        
        Set<Id> relatedEntityIds = new Set<Id>();
        Set<Id> relatedEntityQuoteIds = new Set<Id>();
        Set<Id> relatedEntityProjectIds = new Set<Id>();
        String quotePrefix = SBQQ__Quote__c.sobjecttype.getDescribe().getKeyPrefix();

        for(ContentDocumentLink documentLink : contentDocumentLinks) {
            
            if(((String)documentLink.LinkedEntityId).startsWith('500'))
                relatedEntityIds.add(documentLink.LinkedEntityId);
            if( ((String)documentLink.LinkedEntityId).startsWith(quotePrefix)) 
                relatedEntityQuoteIds.add(documentLink.LinkedEntityId);
        }
        
        // Added code for Quotes
        if(relatedEntityQuoteIds.size() > 0) {
            
            Map<Id, SBQQ__Quote__c> relatedQuotesMap = new Map<Id, SBQQ__Quote__c>([SELECT Id, Document_ID__c FROM SBQQ__Quote__c WHERE Id IN : relatedEntityQuoteIds]);
            
            if(relatedQuotesMap.size() > 0) {
                
                Set<Id> quotesIds = relatedQuotesMap.keySet();
                
                List<ContentDocumentLink> quotesDocumentLinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : quotesIds];
                
                if(quotesDocumentLinks.size() > 0) {
                    
                    Map<Id, String> quoteToDocumentsMap = new Map<Id, String>();
                    
                    for(ContentDocumentLink qDocumentLink : quotesDocumentLinks) {
                        
                        if(quoteToDocumentsMap.containsKey(qDocumentLink.LinkedEntityId)) {
                            
                            String concatenatedDocumentsIds = quoteToDocumentsMap.get(qDocumentLink.LinkedEntityId) + ',' + qDocumentLink.ContentDocumentId;
                            
                            quoteToDocumentsMap.put(qDocumentLink.LinkedEntityId, concatenatedDocumentsIds);
                        }
                        else {
                            
                            quoteToDocumentsMap.put(qDocumentLink.LinkedEntityId, qDocumentLink.ContentDocumentId);
                        }
                    }
                    
                    for(Id quoteId : quoteToDocumentsMap.keySet()) {
                        
                        relatedQuotesMap.get(quoteId).Document_ID__c = quoteToDocumentsMap.get(quoteId);
                    }
                }
                else {
                    
                    for(SBQQ__Quote__c relatedQuote : relatedQuotesMap.values()) {
                        
                        relatedQuote.Document_ID__c = null;
                    }
                }
                System.debug('relatedQuotesMap.values() =====> ' + relatedQuotesMap.values());
                update relatedQuotesMap.values();
            }
        }

        // Existing code for cases
        if(relatedEntityIds.size() > 0) {
            
            Map<Id, Case> relatedCasesMap = new Map<Id, Case>([SELECT Id, Document_Id__c FROM Case WHERE Id IN : relatedEntityIds AND (RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_1 OR
            RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_4 OR RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_5)]);
            
            if(relatedCasesMap.size() > 0) {
                
                Set<Id> casesIds = relatedCasesMap.keySet();
                
                List<ContentDocumentLink> caseDocumentLinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : casesIds];
                
                if(caseDocumentLinks.size() > 0) {
                    
                    Map<Id, String> caseToDocumentsIds = new Map<Id, String>();
                    
                    for(ContentDocumentLink caseDocumentLink : caseDocumentLinks) {
                        
                        if(caseToDocumentsIds.get(caseDocumentLink.LinkedEntityId) != null) {
                            
                            String concatenatedDocumentsIds = caseToDocumentsIds.get(caseDocumentLink.LinkedEntityId) + ',' + caseDocumentLink.ContentDocumentId;
                            
                            caseToDocumentsIds.put(caseDocumentLink.LinkedEntityId, concatenatedDocumentsIds);
                        }
                        else {
                            
                            caseToDocumentsIds.put(caseDocumentLink.LinkedEntityId, caseDocumentLink.ContentDocumentId);
                        }
                    }
                    
                    for(Id caseId : caseToDocumentsIds.keySet()) {
                        
                        relatedCasesMap.get(caseId).Document_Id__c = caseToDocumentsIds.get(caseId);
                    }
                }
                else {
                    
                    for(Case relatedCase : relatedCasesMap.values()) {
                        
                        relatedCase.Document_Id__c = null;
                    }
                }
                
                update relatedCasesMap.values();
            }
        }
    }
    
    private void createNewContentDocumentLinks(List<ContentDocumentLink> newContentDocumentLinks) {
        
        Set<Id> relatedEntityIds = new Set<Id>();
        Set<Id> relatedEntityQuoteIds = new Set<Id>();
        Set<Id> relatedEntityBillingEventIds = new Set<Id>();
        
        String quotePrefix = SBQQ__Quote__c.sobjecttype.getDescribe().getKeyPrefix();
        String billingEventPrefix = pse__Billing_Event__c.SObjectType.getDescribe().getKeyPrefix();
        
        for(ContentDocumentLink newContentDocumentLink : newContentDocumentLinks) {
            
            if(((String)newContentDocumentLink.LinkedEntityId).startsWith('500'))
                relatedEntityIds.add(newContentDocumentLink.LinkedEntityId);
            if( ((String)newContentDocumentLink.LinkedEntityId).startsWith(quotePrefix)) 
                relatedEntityQuoteIds.add(newContentDocumentLink.LinkedEntityId);
            if( ((String)newContentDocumentLink.LinkedEntityId).startsWith(billingEventPrefix))
                relatedEntityBillingEventIds.add(newContentDocumentLink.LinkedEntityId);
        }

        // Added Code for Quote
        if(relatedEntityQuoteIds.size() > 0) {
            
            Map<Id, SBQQ__Quote__c> relatedQuotesMap = new Map<Id, SBQQ__Quote__c>([SELECT Id, SBQQ__Opportunity2__c, RecordType.DeveloperName 
                                                               FROM SBQQ__Quote__c WHERE Id IN : relatedEntityQuoteIds]);
            
            
            if(relatedQuotesMap.size() > 0) {
                
                List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
                
                for(ContentDocumentLink newContentDocumentLink : newContentDocumentLinks) {
                    
                    if(relatedQuotesMap.containsKey(newContentDocumentLink.LinkedEntityId)) {
                        SBQQ__Quote__c relatedQuote = relatedQuotesMap.get(newContentDocumentLink.LinkedEntityId);
                        
                        if(String.isNotEmpty(relatedQuote.SBQQ__Opportunity2__c) ) {
                            
                            ContentDocumentLink newOpportunityContentDocumentLink = new ContentDocumentLink();
                            
                            newOpportunityContentDocumentLink.ContentDocumentId = newContentDocumentLink.ContentDocumentId;
                            newOpportunityContentDocumentLink.LinkedEntityId = relatedQuote.SBQQ__Opportunity2__c;
                            newOpportunityContentDocumentLink.ShareType = 'I';
                            
                            contentDocumentLinksToInsert.add(newOpportunityContentDocumentLink);
                        }
                        if(String.valueOf(UserInfo.getUserId()).substring(0, 15) != DocuSign_Settings__c.getOrgDefaults().Integration_User_Id__c && !Test.isRunningTest()) {
                        
                            ContentDocumentLink newDocuSignUserContentDocumentLink = new ContentDocumentLink();
                            
                            newDocuSignUserContentDocumentLink.ContentDocumentId = newContentDocumentLink.ContentDocumentId;
                            newDocuSignUserContentDocumentLink.LinkedEntityId = DocuSign_Settings__c.getOrgDefaults().Integration_User_Id__c;
                            newDocuSignUserContentDocumentLink.ShareType = 'C';
                        
                            contentDocumentLinksToInsert.add(newDocuSignUserContentDocumentLink);
                        }
                    }
                }
                
                if(contentDocumentLinksToInsert.size() > 0) {
                    
                    insert contentDocumentLinksToInsert;
                }
            }
        }
        
        
        // Existing code for Cases
        if(relatedEntityIds.size() > 0) {
            
            Map<Id, Case> relatedCasesMap = new Map<Id, Case>([SELECT Id, AccountId, ContactId, Opportunity__c, RecordType.DeveloperName 
                                                               FROM Case WHERE Id IN : relatedEntityIds AND (RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_1 OR RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_2 OR RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_4)]);
            
            if(relatedCasesMap.size() > 0) {
                
                List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();
                
                for(ContentDocumentLink newContentDocumentLink : newContentDocumentLinks) {
                    
                    if(relatedCasesMap.containsKey(newContentDocumentLink.LinkedEntityId)) {
                        
                        Case relatedCase = relatedCasesMap.get(newContentDocumentLink.LinkedEntityId);

                        if(String.isNotEmpty(relatedCase.AccountId) && relatedCase.RecordType.DeveloperName != Constants.CASE_RECORD_TYPE_4) {
                            
                            ContentDocumentLink newAccountContentDocumentLink = new ContentDocumentLink();
                            
                            newAccountContentDocumentLink.ContentDocumentId = newContentDocumentLink.ContentDocumentId;
                            newAccountContentDocumentLink.LinkedEntityId = relatedCase.AccountId;
                            newAccountContentDocumentLink.ShareType = 'I';
                            
                            contentDocumentLinksToInsert.add(newAccountContentDocumentLink);
                        }
                        if(String.isNotEmpty(relatedCase.ContactId) && relatedCase.RecordType.DeveloperName != Constants.CASE_RECORD_TYPE_4) {
                            
                            ContentDocumentLink newContactContentDocumentLink = new ContentDocumentLink();
                            
                            newContactContentDocumentLink.ContentDocumentId = newContentDocumentLink.ContentDocumentId;
                            newContactContentDocumentLink.LinkedEntityId = relatedCase.ContactId;
                            newContactContentDocumentLink.ShareType = 'I';
                            
                            contentDocumentLinksToInsert.add(newContactContentDocumentLink);
                        }
                        if(String.isNotEmpty(relatedCase.Opportunity__c) && relatedCase.RecordType.DeveloperName != Constants.CASE_RECORD_TYPE_4) {
                            
                            ContentDocumentLink newOpportunityContentDocumentLink = new ContentDocumentLink();
                            
                            newOpportunityContentDocumentLink.ContentDocumentId = newContentDocumentLink.ContentDocumentId;
                            newOpportunityContentDocumentLink.LinkedEntityId = relatedCase.Opportunity__c;
                            newOpportunityContentDocumentLink.ShareType = 'I';
                            
                            contentDocumentLinksToInsert.add(newOpportunityContentDocumentLink);
                        }
                        if(String.valueOf(UserInfo.getUserId()).substring(0, 15) != DocuSign_Settings__c.getOrgDefaults().Integration_User_Id__c && !Test.isRunningTest()) {
                        
                            ContentDocumentLink newDocuSignUserContentDocumentLink = new ContentDocumentLink();
                            
                            newDocuSignUserContentDocumentLink.ContentDocumentId = newContentDocumentLink.ContentDocumentId;
                            newDocuSignUserContentDocumentLink.LinkedEntityId = DocuSign_Settings__c.getOrgDefaults().Integration_User_Id__c;
                            newDocuSignUserContentDocumentLink.ShareType = 'C';
                        
                            contentDocumentLinksToInsert.add(newDocuSignUserContentDocumentLink);
                        }
                    }
                }
                
                if(contentDocumentLinksToInsert.size() > 0) {
                    try{
                        insert contentDocumentLinksToInsert;
                    } catch (DmlException e){
                        String message = e.getMessage();
                        if(message.contains('DUPLICATE_VALUE')) {
                            Logger.error('Failed to create a ContentDocumentLink because the file is already linked (Duplicate_Value error)');
                            Logger.saveLog();
                        } else {
                            throw e;
                        }
                    }
                }
            }
        }

        // Added Code for BillingEvent
        if(relatedEntityBillingEventIds.size() > 0) {

            Map<Id, pse__Billing_Event__c> relatedBillingEventsMap = new Map<Id, pse__Billing_Event__c>([SELECT Id
            FROM pse__Billing_Event__c WHERE Id IN : relatedEntityBillingEventIds]);


            if(relatedBillingEventsMap.size() > 0) {

                List<ContentDocumentLink> contentDocumentLinksToInsert = new List<ContentDocumentLink>();

                for(ContentDocumentLink newContentDocumentLink : newContentDocumentLinks) {

                    if(relatedBillingEventsMap.containsKey(newContentDocumentLink.LinkedEntityId)) {

                        if(String.valueOf(UserInfo.getUserId()).substring(0, 15) != DocuSign_Settings__c.getOrgDefaults().Integration_User_Id__c && !Test.isRunningTest()) {

                            ContentDocumentLink newDocuSignUserContentDocumentLink = new ContentDocumentLink();

                            newDocuSignUserContentDocumentLink.ContentDocumentId = newContentDocumentLink.ContentDocumentId;
                            newDocuSignUserContentDocumentLink.LinkedEntityId = DocuSign_Settings__c.getOrgDefaults().Integration_User_Id__c;
                            newDocuSignUserContentDocumentLink.ShareType = 'C';

                            contentDocumentLinksToInsert.add(newDocuSignUserContentDocumentLink);
                        }
                    }
                }

                if(contentDocumentLinksToInsert.size() > 0) {

                    insert contentDocumentLinksToInsert;
                }
            }
        }
    }
}