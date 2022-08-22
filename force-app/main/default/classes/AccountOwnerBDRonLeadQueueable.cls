/**
 * update lead owner is Account.OwnerId is changed or Account.EDR__c (BDR) is changed
 */
public with sharing class AccountOwnerBDRonLeadQueueable extends AbstractQueueable {
  private final List<SObject> accountsLst;
  private final Map<Id, SObject> oldAccountsMap;

  public AccountOwnerBDRonLeadQueueable(List<SObject> accountsLst, Map<Id, SObject> oldAccountsMap) {
    super('AccountOwnerBDRonLeadQueueable');
    this.accountsLst = accountsLst;
    this.oldAccountsMap = oldAccountsMap;
  }

  public override void work() {
    this.updateLeadsOwner(this.accountsLst, this.oldAccountsMap);
  }

   private void updateLeadsOwner(List<Account> accountList, Map<Id, SObject> oldAccountsMap) {
     Set<String> leadsStatuses = new Set<String>{'Accepted', 'MQL'};
     Map<Id, List<Lead>> leadsMap = new Map<Id, List<Lead>>();
     for(Lead l: [SELECT Id, OwnerId, Account__c FROM Lead WHERE Account__c IN: accountList AND Status IN: leadsStatuses]) {
       if(!leadsMap.containsKey(l.Account__c)) {
         leadsMap.put(l.Account__c, new List<Lead>{l});
       } else {
         List<Lead> exList = leadsMap.get(l.Account__c);
         exList.add(l);
         leadsMap.put(l.Account__c, exList);
       }
     }
     List<Lead> leadsToUpdate = new List<Lead>();
     for(Account a: accountList) {
       Account oldAcc = (Account)oldAccountsMap.get(a.Id);
       List<Lead> relatedLeads = leadsMap.get(a.Id);
       for(Lead l: relatedLeads) {
         if(a.EDR__c != oldAcc.EDR__c) {
           if(a.EDR__c != null) {
             l.OwnerId = a.EDR__c;
           } else {
             l.OwnerId = a.OwnerId;
           }
           leadsToUpdate.add(l);
         } else {
           if(a.OwnerId != oldAcc.OwnerId && a.OwnerId != l.OwnerId) {
             l.OwnerId = a.OwnerId;
             leadsToUpdate.add(l);
           }
         }
       }
     }
     
     if(leadsToUpdate.size() > 0) {
       update leadsToUpdate;
     }
   }
   
  /**
   * update lead owner is Account.OwnerId is changed or Account.EDR__c (BDR) is changed
   * @param existingRecords
   */
  public static void updateOwnerOnRelatedLeads(List<Account> accounts, Map<Id, SObject> existingAccounts) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Account.OwnerId, Account.EDR__c},
      accounts,
      existingAccounts
    );
    List<Account> eligibleAccounts = (List<Account>) Collection.of(accounts)
      .filter(hasChanged)
      .asList();

    if (!eligibleAccounts.isEmpty()) {
      AbstractQueueable.enqueue(new AccountOwnerBDRonLeadQueueable(eligibleAccounts, existingAccounts));
    }
  }
}