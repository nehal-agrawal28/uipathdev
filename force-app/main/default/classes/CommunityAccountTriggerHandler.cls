public with sharing class CommunityAccountTriggerHandler {
    
    public void onAfterInsert(List<Account> newList, Map<Id, Account> newMap) {
        shareSameAccount(newList);
        clearOwnerFromLead(newList);
    }
    
    public void onAfterUpdate(List<Account> newList, Map<Id, Account> newMap, List<Account> oldList, Map<Id, Account> oldMap) {
        shareSameAccount(newList);
        clearOwnerFromLead(newList);
    }
    
    private void shareSameAccount(List<Account> newList) {
        Set<ID> leadOwnerIdSet = new Set<ID>();
        for (Account acc : newList) {
            if (String.isNotEmpty(acc.OwnerFromLead__c)) {
                leadOwnerIdSet.add(acc.OwnerFromLead__c);
            }
        }
        
        if (!leadOwnerIdSet.isEmpty()) {
            // リード所有者の取引先ID取得
            Map<ID, User> leadOwnerMap = new Map<ID, User>([SELECT Id, Contact.AccountId FROM User WHERE IsActive = true AND ContactId != null AND Id IN :leadOwnerIdSet]);
            
            if (!leadOwnerMap.isEmpty()) {
                Set<ID> accIdSet = new Set<ID>();
                for (User u : leadOwnerMap.values()) {
                    accIdSet.add(u.Contact.AccountId);
                }
                
                // 同一取引先所属のユーザ取得
                List<User> communityUserAccList = [SELECT Id, Contact.AccountId FROM User WHERE IsActive = true AND Contact.AccountId IN :accIdSet];
                
                List<AccountShare> accShareList = new List<AccountShare>();
                
                for (Account acc : newList) {
                    if (String.isNotEmpty(acc.OwnerFromLead__c)) {
                        // 所有者の所属取引先
                        ID ownerAccId = leadOwnerMap.get(acc.OwnerFromLead__c).Contact.AccountId;
                        
                        // 同一取引先所属のユーザに共有設定
                        for (User u : communityUserAccList) {
                            if (ownerAccId == u.Contact.AccountId) {
                                accShareList.add(new AccountShare(
                                    AccountId = acc.Id,
                                    UserOrGroupId = u.Id,
                                    AccountAccessLevel = 'Read',
                                    OpportunityAccessLevel = 'None'
                                ));
                            }
                        }
                    }
                }
                
                if (!accShareList.isEmpty()) {
                    insert accShareList;
                }
                
            }
        }
    }
    
    private void clearOwnerFromLead(List<Account> newList) {
        
        List<Account> updAccList = new List<Account>();
        
        for (Account acc : newList) {
            if (String.isNotEmpty(acc.OwnerFromLead__c)) {
                updAccList.add(new Account(Id = acc.Id, OwnerFromLead__c = null));
            }
        }
        
        if (!updAccList.isEmpty()) {
            update updAccList;
        }
    }
}