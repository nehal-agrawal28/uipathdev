/**
*
* Author:       Daniel Sarchiz
* Date:         20/11/2017
* Description:  Trigger handler class for DocuSign Status
*
**/

public class DocuSignStatusTriggerHandler {
    
    private boolean isExecuting = false;
    private integer batchSize = 0;
    
    public DocuSignStatusTriggerHandler(boolean triggerExecuting, integer size) {
        
        isExecuting = triggerExecuting;
        BatchSize = size;
    }
    
    public void onBeforeInsert(List<dsfs__DocuSign_Status__c> newDocuSignStatuses) {
        
        populateObjectLookupFields(newDocuSignStatuses);
        
        updateCaseStatus(newDocuSignStatuses, null);
    }
    
    public void onBeforeUpdate(List<dsfs__DocuSign_Status__c> newDocuSignStatuses, Map<Id, dsfs__DocuSign_Status__c> oldDocuSignStatusesMap) {
        populateObjectLookupFields(newDocuSignStatuses);
        updateCaseStatus(newDocuSignStatuses, oldDocuSignStatusesMap);
    }
    
    // Business Logic
    
    private void populateObjectLookupFields(List<dsfs__DocuSign_Status__c> newDocuSignStatuses) {
        
        List<dsfs__DocuSign_Status__c> changedDocuSignStatuses = new List<dsfs__DocuSign_Status__c>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        
        for(dsfs__DocuSign_Status__c newDocuSignStatus : newDocuSignStatuses) {
            
            if(String.isNotEmpty(newDocuSignStatus.dsfs__Case__c)) {
                changedDocuSignStatuses.add(newDocuSignStatus);
                caseIds.add(newDocuSignStatus.dsfs__Case__c);
            }
            // added functionality for Quote - 11/20/2019
            if(String.isNotEmpty(newDocuSignStatus.Quote__c)) {
                changedDocuSignStatuses.add(newDocuSignStatus);
                quoteIds.add(newDocuSignStatus.Quote__c);
            }
        }
        
        if(caseIds.size() > 0 || quoteIds.size() > 0) {
            
            Map<Id, Case> relatedCases = new Map<Id, Case>([SELECT Id, AccountId, ContactId, Opportunity__c, RecordType.DeveloperName 
                                                               FROM Case WHERE Id IN : caseIds AND (RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_1 OR RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_4)]);
            
            // added functionality for Quote - 11/20/2019
            Map<Id, SBQQ__Quote__c> relatedQuotes = new Map<Id, SBQQ__Quote__c>([SELECT Id, SBQQ__Account__c, SBQQ__PrimaryContact__c, SBQQ__Opportunity2__c, RecordType.DeveloperName 
                                                               FROM SBQQ__Quote__c WHERE Id IN : quoteIds ]);
            
            
            for(dsfs__DocuSign_Status__c changedDocuSignStatus : changedDocuSignStatuses) {
                
                // added functionality for Quote - 11/20/2019
                if( relatedQuotes.containsKey(changedDocuSignStatus.Quote__c)) 
                {
                    SBQQ__Quote__c relatedQuote = relatedQuotes.get(changedDocuSignStatus.Quote__c);
                    if(String.isNotEmpty(relatedQuote.SBQQ__Account__c))
                        changedDocuSignStatus.dsfs__Company__c = relatedQuote.SBQQ__Account__c;
                        
                    if(String.isNotEmpty(relatedQuote.SBQQ__PrimaryContact__c))
                        changedDocuSignStatus.dsfs__Contact__c = relatedQuote.SBQQ__PrimaryContact__c; 
                         
                    if(String.isNotEmpty(relatedQuote.SBQQ__Opportunity2__c))
                        changedDocuSignStatus.dsfs__Opportunity__c = relatedQuote.SBQQ__Opportunity2__c; 
                }
                
                // existing functionality for Cases
                if( relatedCases.containsKey(changedDocuSignStatus.dsfs__Case__c)) 
                {
                    Case relatedCase = relatedCases.get(changedDocuSignStatus.dsfs__Case__c);
                    
                    if(String.isNotEmpty(relatedCase.AccountId) && relatedCase.RecordType.DeveloperName != Constants.CASE_RECORD_TYPE_4) {
                        
                        changedDocuSignStatus.dsfs__Company__c = relatedCase.AccountId;
                    } else {
                        changedDocuSignStatus.dsfs__Company__c = null;
                    }
                    
                    if(String.isNotEmpty(relatedCase.ContactId) && relatedCase.RecordType.DeveloperName != Constants.CASE_RECORD_TYPE_4) {
                        
                        changedDocuSignStatus.dsfs__Contact__c = relatedCase.ContactId;
                    } else {
                        changedDocuSignStatus.dsfs__Contact__c = null;
                    }
                    
                    if(String.isNotEmpty(relatedCase.Opportunity__c) && relatedCase.RecordType.DeveloperName != Constants.CASE_RECORD_TYPE_4) {
                        
                        changedDocuSignStatus.dsfs__Opportunity__c = relatedCase.Opportunity__c;
                    } else {
                        changedDocuSignStatus.dsfs__Opportunity__c = null;
                    }
                }
            }
        }
    }
    
    private void updateCaseStatus(List<dsfs__DocuSign_Status__c> newDocuSignStatuses, Map<Id, dsfs__DocuSign_Status__c> oldDocuSignStatusesMap) {
        
        List<dsfs__DocuSign_Status__c> changedDocuSignStatuses = new List<dsfs__DocuSign_Status__c>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> quoteIds = new Set<Id>();
        
        for(dsfs__DocuSign_Status__c newDocuSignStatus : newDocuSignStatuses) {
            
            if (oldDocuSignStatusesMap == null) {
                changedDocuSignStatuses.add(newDocuSignStatus);
                if(String.isNotEmpty(newDocuSignStatus.dsfs__Case__c))
                    caseIds.add(newDocuSignStatus.dsfs__Case__c);
                if(String.isNotEmpty(newDocuSignStatus.Quote__c))
                    quoteIds.add(newDocuSignStatus.Quote__c); 
            } else {
                dsfs__DocuSign_Status__c oldDocuSignStatus = oldDocuSignStatusesMap.get(newDocuSignStatus.Id);
                
                if((oldDocuSignStatus != null &&  newDocuSignStatus.dsfs__Envelope_Status__c != oldDocuSignStatus.dsfs__Envelope_Status__c && 
                      (newDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_1 || newDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_2 || 
                       newDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_3 ||  newDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_4 || 
                       newDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_5)) || 
                       (newDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_1 ||  newDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_2 ||  
                       newDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_3 || newDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_4 ||  
                       newDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_5)
                   && (String.isNotEmpty(newDocuSignStatus.dsfs__Case__c) || String.isNotEmpty(newDocuSignStatus.Quote__c))) {
                    
                    changedDocuSignStatuses.add(newDocuSignStatus);
                    if(String.isNotEmpty(newDocuSignStatus.dsfs__Case__c))
                        caseIds.add(newDocuSignStatus.dsfs__Case__c);
                    if(String.isNotEmpty(newDocuSignStatus.Quote__c))
                        quoteIds.add(newDocuSignStatus.Quote__c); 
                }
            }
        }        
        
        if(quoteIds.size() > 0) {
            
            Map<Id, SBQQ__Quote__c> relatedQuotes = new Map<Id, SBQQ__Quote__c>([SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id IN : quoteIds ]);
            
            for(dsfs__DocuSign_Status__c changedDocuSignStatus : changedDocuSignStatuses) {
                
                if(relatedQuotes.containsKey(changedDocuSignStatus.Quote__c)) {
                    SBQQ__Quote__c relatedQuote = relatedQuotes.get(changedDocuSignStatus.Quote__c);

                    /*if (changedDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_1) {
                        relatedQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_4;
                    }
                    if (changedDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_2) {
                        relatedQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_5;
                    }
                    if (changedDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_3) {
                        relatedQuote.SBQQ__Status__c = Constants.DOCUSIGN_ENVELOPE_STATUS_3;
                    }
                    
                    if (changedDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_4 || changedDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_5) {
                        relatedQuote.SBQQ__Status__c = Constants.QUOTE_STATUS_7;
                    }*/
                    
                    //relatedQuote.Reason__c = changedDocuSignStatus.dsfs__Envelope_Status__c;
                }
            }
             
            update relatedQuotes.values();
        }
        
        if(caseIds.size() > 0) {
            
            Map<Id, Case> relatedCases = new Map<Id, Case>([SELECT Id, Status, IsClosed, Reason__c, Account.Area__c, Account_Region__c  FROM Case WHERE Id IN : caseIds AND (RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_1 OR RecordType.DeveloperName =: Constants.CASE_RECORD_TYPE_4)]);
            
            for(dsfs__DocuSign_Status__c changedDocuSignStatus : changedDocuSignStatuses) {
                
                Case relatedCase = relatedCases.get(changedDocuSignStatus.dsfs__Case__c);
                
                if(relatedCase != null && relatedCase.isClosed == false) {
                    
                    //relatedCase.Status = Constants.CASE_STATUS_7; 
                    if (changedDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_1 && relatedCase.Account.Area__c != 'Japan') {
                        relatedCase.Status = Constants.CASE_STATUS_2;
                        relatedcase.Executed_contract_version_attached__c = 'Yes';
                    }
                    if (changedDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_2 && relatedCase.Account.Area__c != 'Japan') {
                        relatedCase.Status = Constants.CASE_STATUS_3;
                    }
                    if (changedDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_3) {
                        relatedCase.Status = Constants.CASE_STATUS_9;
                    }
                    
                    if (changedDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_4 || changedDocuSignStatus.dsfs__Envelope_Status__c == Constants.DOCUSIGN_ENVELOPE_STATUS_5) {
                        relatedCase.Status = Constants.CASE_STATUS_8;
                    }
                    
                    relatedCase.Reason__c = changedDocuSignStatus.dsfs__Envelope_Status__c;
                }
            }
             
            update relatedCases.values();
        }
    }
}