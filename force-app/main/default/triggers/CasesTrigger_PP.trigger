trigger CasesTrigger_PP on Case
(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    fflib_SObjectDomain.triggerHandler(CasesTriggerHandler_PP.class);
    if(trigger.isAfter){
        if(trigger.isInsert || trigger.isUpdate){
            List<Id> dealHubCaseId = new List<Id>();
            List<Id> legalReviewCaseId = new List<Id>();
            List<Id> financeReviewCaseId = new List<Id>();
            List<Id> readyForSignatureCaseId = new List<Id>();
            List<Id> masterDataCaseId = new List<Id>();
            Id devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Legal Request').getRecordTypeId();
            Id devRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Finance Request').getRecordTypeId();
            for(case cs: trigger.new){
                if(cs.Status == 'Deal Hub Review' && cs.Deal_Hub_Owner__c == null){
                    dealHubCaseId.add(cs.Id);
                }else if( cs.Status =='Legal Review' && cs.Legal_Owner__c == null){
                    legalReviewCaseId.add(cs.Id);
                }else if( cs.Status =='Finance Review' && cs.Finance_Owner__c == null){
                    financeReviewCaseId.add(cs.Id);
                }else if( cs.Status== 'Ready for signature' && cs.Deal_Hub_Owner__c == null && cs.RecordTypeId==devRecordTypeId){
                    readyForSignatureCaseId.add(cs.Id);
                }else if(cs.Status == 'Master Data Review' && cs.Master_Data_Owner__c == null && cs.RecordTypeId==devRecTypeId){
                    masterDataCaseId.add(cs.Id);
                } 
            }
            if(dealHubCaseId.size()>0){        
                AssignCasesUsingAssignmentRules.CaseAssign(dealHubCaseId); 
            }
            if(legalReviewCaseId.size()>0){        
                AssignCasesUsingAssignmentRules.CaseAssign(legalReviewCaseId); 
            }
            if(financeReviewCaseId.size()>0){        
                AssignCasesUsingAssignmentRules.CaseAssign(financeReviewCaseId);  
            }
            if(readyForSignatureCaseId.size()>0){        
                AssignCasesUsingAssignmentRules.CaseAssign(readyForSignatureCaseId);  
            }
            if(masterDataCaseId.size()>0){        
                AssignCasesUsingAssignmentRules.CaseAssign(masterDataCaseId); 
            }
        } 
    }
}