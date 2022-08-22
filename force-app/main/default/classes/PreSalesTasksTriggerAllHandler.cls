/********************************************************************************************************
*    Handler Name:  PreSalesTasksTriggerAllHandler.cls
*    Author: Mirela Chituc (mirela.chituc@uipath.com) 
*    Date:  10/23/2019
*    
*    Trigger: PreSalesTasksTriggerAll.trigger
*    Test class: PreSalesTasksTriggerAllHandlerTest.cls
********************************************************************************************************/

public without sharing class PreSalesTasksTriggerAllHandler {
    
    //Handler for before insert methods
    public void onBeforeInsert(list<Pre_Sales_Tasks__c> newList , map<id, Pre_Sales_Tasks__c> newMap) {
        setUpGroupMemberAsOwner(newList);
    }
    //Handler for after insert methods
    public void onAfterInsert(list<Pre_Sales_Tasks__c> newList , map<id, Pre_Sales_Tasks__c> newMap) {
       setUsedEffort(newList, newMap, 'insert');
    }
    //Handler for before Update methods
    public void onBeforeUpdate(list<Pre_Sales_Tasks__c> newList, map<id, Pre_Sales_Tasks__c> newMap , map<id, Pre_Sales_Tasks__c> oldMap) {
        preventUserOutsideQueueAsOwner(newList);
    }
    //Handler for after Update methods
    public void onAfterUpdate(list<Pre_Sales_Tasks__c> newList, map<id, Pre_Sales_Tasks__c> newMap,  map<id, Pre_Sales_Tasks__c> oldMap) {
        setUsedEffort(newList, oldMap, 'update');
    }

    //Handler for before Deletes methods
    public void onBeforeDelete(list<Pre_Sales_Tasks__c> oldList , map<id, Pre_Sales_Tasks__c> oldMap) {
        setUsedEffort(oldList, oldMap, 'delete');
    }
    //Handler for after Deletes methods
    public void onAfterDelete(list<Pre_Sales_Tasks__c> oldList , map<id, Pre_Sales_Tasks__c> oldMap) {
        
    }
    
    // assign record to groupMember
    private void setUpGroupMemberAsOwner(List<Pre_Sales_Tasks__c> PreSalesTasksList) {
        
        Id LearningConsultingRecType = SObjectType.Pre_Sales_Tasks__c.getRecordTypeInfosByDeveloperName().get('Learning_Consulting').getRecordTypeId();
        List<Group> theQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND NAME = 'Learning Consulting Team' LIMIT 1];
        for (Pre_Sales_Tasks__c pst : PreSalesTasksList)
            if(pst.RecordTypeId == LearningConsultingRecType && theQueue.size() == 1)
                pst.OwnerId = theQueue[0].Id;
    }

    // assign record to groupMember
    private void preventUserOutsideQueueAsOwner(List<Pre_Sales_Tasks__c> PreSalesTasksList) {
        
        Id LearningConsultingRecType = SObjectType.Pre_Sales_Tasks__c.getRecordTypeInfosByDeveloperName().get('Learning_Consulting').getRecordTypeId();
        Set<Id> GMIds = new Set<Id>();
        Id GroupId = null;
        for(GroupMember gm: [SELECT Id, UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.NAME = 'Learning Consulting Team' ]) {
            GMIds.add(gm.UserOrGroupId);
            if(!GMIds.contains(gm.GroupId))
                GMIds.add(gm.GroupId);
        }
        for (Pre_Sales_Tasks__c pst : PreSalesTasksList)
            if(pst.RecordTypeId == LearningConsultingRecType && !GMIds.contains(pst.OwnerId))
                pst.addError('You cannot assign record to a user outside the queue.');
    }

    /* Private Methods */
    // ============================================================================
    // added by Mirela Chituc - 10/23/2019 ========================================
    // Set up Used Effort
    // ============================================================================
    private void setUsedEffort(List<Pre_Sales_Tasks__c> PreSalesTasksList, Map<Id, Pre_Sales_Tasks__c> oldPreSalesTasksMap, String action) {
        
        
        Set<String> allTypes = new Set<String>{'Workshop', 'POC', 'Demo'};
        Set<Id> pstIds = new Set<Id>();
        Set<Id> delpstIds = new Set<Id>();
        for (Pre_Sales_Tasks__c pst : PreSalesTasksList) {
            pstIds.add(pst.Id);
            if(action == 'delete')
                delpstIds.add(pst.Id);
        }
        
        List<Pre_Sales_Tasks__c> allCurrentPSTasks = [SELECT Id, Opportunity__c, Opportunity__r.AccountId
                                               FROM Pre_Sales_Tasks__c WHERE Type__c IN: allTypes AND Id IN: pstIds];
        
        if(allCurrentPSTasks.size() > 0) {
            Set<Id> accIds = new Set<Id>();
            for(Pre_Sales_Tasks__c pst: allCurrentPSTasks)
                if(!String.isEmpty(pst.Opportunity__r.AccountId))
                    accIds.add(pst.Opportunity__r.AccountId);
            
            List<Pre_Sales_Tasks__c> allPre_Sales_Tasks = [SELECT Id, Opportunity__c, Opportunity__r.AccountId, Duration_in_hours__c
                                                   FROM Pre_Sales_Tasks__c WHERE Type__c IN: allTypes AND Opportunity__r.AccountId IN: accIds AND Id NOT IN: delpstIds];
            
            if(allPre_Sales_Tasks.size() > 0) {
                Map<Id, Decimal> preSalesDuretionByAccountMap = new Map<Id, Decimal>();
                for(Pre_Sales_Tasks__c pSales: allPre_Sales_Tasks)
                {
                    if(pSales.Duration_in_hours__c != null) {
                        if(!preSalesDuretionByAccountMap.containsKey(pSales.Opportunity__r.AccountId))
                            preSalesDuretionByAccountMap.put(pSales.Opportunity__r.AccountId, pSales.Duration_in_hours__c);
                        else {
                            Decimal totalDuration = preSalesDuretionByAccountMap.get(pSales.Opportunity__r.AccountId);
                            totalDuration += pSales.Duration_in_hours__c;
                            preSalesDuretionByAccountMap.put(pSales.Opportunity__r.AccountId, totalDuration);
                        }
                    }
                }
                
                if(preSalesDuretionByAccountMap.size() > 0) {
                    List<Account> allAccounts = [SELECT Id, Used_Effort__c FROM Account WHERE Id IN: accIds/*preSalesDuretionByAccountMap.keySet()*/];
                    for(Account acc: allAccounts)
                        if(preSalesDuretionByAccountMap.containsKey(acc.Id))
                            acc.Used_Effort__c = preSalesDuretionByAccountMap.get(acc.Id);
                            
                    update allAccounts;
                }
            }
        }
    }
}