/********************************************************************************************************
 *    Handler Name:  ContactTriggerAllHandler.cls
 *    Author: Mirela Chituc (mirela.chituc@uipath.com)
 *    Date:  10/3/2019
 *
 *    Trigger: ContactTriggerAll.trigger
 *    Test class: ContactTriggerAllHandlerTest.cls
 ********************************************************************************************************/

public without sharing class ContactTriggerAllHandler {
  //Handler for before insert methods
  public void onBeforeInsert(list<Contact> newList, map<id, Contact> newMap) {
    setUpContactOwner(newList, null);
  }
  //Handler for after insert methods
  public void onAfterInsert(list<Contact> newList, map<id, Contact> newMap, map<id, Contact> oldMap) {
    SetUpEmailDomainOnAccount(newList, newMap, 'insert');
    populateAPContactOnAccount(newList, oldMap);
    //ContactFunnelQueueable_MK.contactFunnelOnInsert(newList);
  }

  //Handler for before Update methods
  public void onBeforeUpdate(list<Contact> newList, map<id, Contact> newMap, map<id, Contact> oldMap) {
    setUpCurrentSequenceDate(newList, oldMap);
    SetUpMQLContactStatus(newList, oldMap);
    setUpContactOwner(newList, oldMap);
  }
  //Handler for after Update methods
  public void onAfterUpdate(list<Contact> newList, map<id, Contact> newMap, map<id, Contact> oldMap) {
    SetUpEmailDomainOnAccount(newList, oldMap, 'update');
    populateAPContactOnAccount(newList, oldMap);
    removeAPContactOnAccount(newList, oldMap);
    //ContactFunnelQueueable_MK.contactFunnelOnUpdate(newList, oldMap);
  }

  //Handler for before Deletes methods
  public void onBeforeDelete(list<Contact> oldList, map<id, Contact> oldMap) {
  }
  //Handler for after Deletes methods
  public void onAfterDelete(list<Contact> oldList, map<id, Contact> oldMap) {
    SetUpEmailDomainOnAccount(oldList, oldMap, 'delete');
  }

  private void setUpCurrentSequenceDate(List<Contact> cntList, Map<Id, Contact> cntOldMap) {
    for (Contact cnt : cntList) {
      Contact oldContact = cntOldMap.get(cnt.Id);
      if (
        cnt.Outreach_Current_Sequence_Name__c != null &&
        cnt.Outreach_Current_Sequence_Name__c != oldContact.Outreach_Current_Sequence_Name__c
      )
        cnt.Outreach_Date_Added_to_Sequence__c = Date.Today();
      if (cnt.Outreach_Current_Sequence_Name__c == null)
        cnt.Outreach_Date_Added_to_Sequence__c = null;
    }
  }

  // ============================================================================
  // added by Mirela Chituc - 5/26/2020 ========================================
  // Set up Account Owner as Contact Owner to all Conatcts - before insert, before update
  // ============================================================================
  private void setUpContactOwner(List<Contact> contactList, Map<Id, Contact> contactOldMap) {
    Set<Id> acnIds = new Set<Id>();
    for (Contact cnt : contactList) {
      acnIds.add(cnt.AccountId);
    }
    if (acnIds.size() > 0) {
      Map<Id, Account> accountsMap = new Map<Id, Account>(
        [
          SELECT Id, OwnerId, KAM_Id__c, EDR__c
          FROM Account
          WHERE Id IN :acnIds AND PG_Legacy__c = FALSE AND Country__c != 'Japan'
        ]
      );
      for (contact cnt : contactList) {
        if (accountsMap.containsKey(cnt.AccountId)) {
          Account currentAcc = accountsMap.get(cnt.AccountId);
          String cntOwner = String.valueOf(cnt.OwnerId);
          cntOwner = cntOwner.substring(0, 15);
          if (
            cntOwner != currentAcc.KAM_Id__c &&
            cnt.OwnerId != currentAcc.EDR__c &&
            cnt.OwnerId != currentAcc.OwnerId
          ) {
            cnt.OwnerId = currentAcc.OwnerId;
          }
        }
      }
    }
  }

  private void SetUpMQLContactStatus(list<Contact> contactList, map<id, Contact> contactOldMap) {
    for (Contact c : contactList) {
      if (contactOldMap != null) {
        Contact oldContact = contactOldMap.get(c.Id);
        if (c.Latest_Contact_Us_Date__c != oldContact.Latest_Contact_Us_Date__c) {
          c.Contact_Status__c = 'MQL';
          c.Date_Time_MQL__c = DateTime.Now();
        }
      }
    }
  }

  /*private void SetUpContactStatus(list<Contact> contactList, map<id, Contact> contactOldMap) {
        List<Lead> convertedLead = [SELECT Id, ConvertedContactId FROM Lead WHERE ConvertedContactId IN: contactList AND ConvertedContactId != null];
        Map<Id, Id> leadContactMap = new Map<Id, Id>();
        Set<Id> contactsIds = new Set<Id>();
        for(Lead l: convertedLead) {
            leadContactMap.put(l.Id, l.ConvertedContactId);
            contactsIds.add(l.ConvertedContactId);
        }
        for(Contact cnt: contactList) {
            if(!contactsIds.contains(cnt.Id))
                contactsIds.add(cnt.Id);
        }
        
        List<Task> leadTasks = [SELECT Id, WhoId FROM Task WHERE (WhoId IN: leadContactMap.keySet() OR WhoId IN: contactsIds) AND WhoId != null];
        Set<Id> activeContacts = new Set<Id>();
        for(Task lt: leadTasks) {
            String sWhoId = String.valueOf(lt.WhoId);
            if(sWhoId != null) {
                if(sWhoId.startsWith('00Q')) {
                    if(leadContactMap.containsKey(lt.WhoId))
                        activeContacts.add(leadContactMap.get(lt.WhoId));
                } else {
                    activeContacts.add(lt.WhoId);
                }
            }
        }

        for(Contact c: contactList) {
            if(c.Contact_Status__c  != 'Influencer') {
                if(c.Contact_Status__c  != 'New' && c.Contact_Status__c  != 'Added to Opportunity') {
                    c.Contact_Status__c = 'Dormant';
                    if(contactsIds.contains(c.Id)) {
                        c.Contact_Status__c = 'Converted from Lead';
                        c.Date_Time_Converted_from_Lead__c = DateTime.Now();
                    }
                    if(activeContacts.contains(c.Id)) {
                        c.Contact_Status__c = 'Actively engaged';
                        c.Date_Time_Actively_engaged__c = DateTime.Now();
                    }
                }
                if(contactOldMap != null) {
                    Contact oldContact = contactOldMap.get(c.Id);
                    if(c.Latest_Contact_Us_Date__c != oldContact.Latest_Contact_Us_Date__c) {
                        c.Contact_Status__c = 'New';
                        c.Date_Time_New__c = DateTime.Now();
                    }
                    if(c.Contact_Status__c != oldContact.Contact_Status__c) {
                        if(c.Contact_Status__c == 'Influencer')
                            c.Date_Time_Influencer__c = DateTime.Now();
                        if(c.Contact_Status__c == 'Dormant')
                            c.Date_Time_Dormant__c = DateTime.Now();
                    }
                }
            }
        }
    }*/

  private void SetUpEmailDomainOnAccount(
    list<Contact> contactList,
    map<id, Contact> contactOldMap,
    String triggerAction
  ) {
    Set<Id> accountIds = new Set<Id>();

    for (Contact cont : contactList) {
      if (triggerAction == 'insert') {
        accountIds.add(cont.AccountId);
      } else {
        Contact oldContact = contactOldMap.get(cont.Id);
        if (triggerAction == 'update')
          if (cont.Email != oldContact.Email)
            accountIds.add(cont.AccountId);
        if (triggerAction == 'delete')
          accountIds.add(oldContact.AccountId);
      }
    }

    if (accountIds.size() > 0) {
      List<Account> allAccounts = [
        SELECT Id, Name, Email_Domain__c
        FROM Account
        WHERE Id IN :accountIds AND Email_Domain_Disabled__c = FALSE
      ];
      if (allAccounts.size() > 0) {
        // Select all related Contacts
        List<String> emailexceptions = new List<String>{ '%gmail.com', '%hotmail.com', '%yahoo.com' };
        List<Contact> cntList = [
          SELECT Id, AccountId, Email
          FROM Contact
          WHERE
            AccountId IN :allAccounts
            AND Email != NULL
            AND (NOT Email LIKE :emailexceptions)
            AND Public_Email__c = FALSE
        ];
        Map<Id, List<Contact>> cntMap = new Map<Id, List<Contact>>();
        // populate map: key - account id, value = list of the related contacts for that accounts
        for (Contact cnt : cntList) {
          if (!cntMap.containsKey(cnt.AccountId)) {
            List<Contact> newCntList = new List<Contact>();
            newCntList.add(cnt);
            cntMap.put(cnt.AccountId, newCntList);
          } else {
            List<Contact> exCntList = cntMap.get(cnt.AccountId);
            exCntList.add(cnt);
            cntMap.put(cnt.AccountId, exCntList);
          }
        }
        List<Account> accToUpdate = new List<Account>();
        for (Account acc : allAccounts) {
          if (cntMap.containsKey(acc.Id)) {
            //Take all contacts related to current account
            List<Contact> currentContacts = cntMap.get(acc.Id);
            Map<String, Integer> emailDomainMap = new Map<String, Integer>();
            for (Contact c : currentContacts) {
              if (!String.isEmpty(c.Email) && (c.Email).contains('@')) {
                String emailDomain = (c.Email).substring((c.Email).indexOf('@') + 1, (c.Email).length());
                if (emailDomain != 'gmail.com') {
                  if (!emailDomainMap.containsKey(emailDomain)) {
                    emailDomainMap.put(emailDomain, 1);
                  } else {
                    Integer eDomNo = emailDomainMap.get(emailDomain);
                    emailDomainMap.put(emailDomain, eDomNo + 1);
                  }
                }
              }
            }
            //System.debug('emailDomainMap =====>' + emailDomainMap);

            String maxSize = '';
            for (String key : emailDomainMap.keyset())
              if (maxSize == '' || emailDomainMap.get(key) > emailDomainMap.get(maxSize))
                maxSize = key;
            //System.debug('maxSize =====>' + maxSize);

            acc.Email_Domain__c = maxSize;
            accToUpdate.add(acc);
          } else {
            acc.Email_Domain__c = '';
            accToUpdate.add(acc);
          }
        }
        if (accToUpdate.size() > 0)
          update accToUpdate;
      }
    }
  }

  public static void populateAPContactOnAccount(List<Contact> conList, Map<Id, Contact> contactOldMap) {
    Map<ID, Id> accToContactMap = new Map<Id, Id>();
    Contact oldContact;
    for (Contact c : conList) {
      if (contactOldMap != null) {
        oldContact = contactOldMap.get(c.Id);
      }
      if (
        c.Role__c == 'Accounts Payable' &&
        (contactOldMap == null || (contactOldMap != null && c.Role__c != oldContact.Role__c))
      ) {
        accToContactMap.put(c.AccountId, c.Id);
      }
    }
    if (accToContactMap.size() > 0) {
      List<Account> accountToUpdate = new List<Account>();
      for (Account acc : [SELECT Id, AP_Contact__c FROM Account WHERE Id IN :accToContactMap.keySet()]) {
        acc.AP_Contact__c = accToContactMap.get(acc.Id);
        accountToUpdate.add(acc);
      }
      update accountToUpdate;
    }
  }

  public static void removeAPContactOnAccount(List<Contact> conList, Map<Id, Contact> contactOldMap) {
    Set<ID> accIds = new Set<Id>();
    List<Account> accountsToUpdate = new List<Account>();
    Contact oldContact;
    for (Contact c : conList) {
      if (contactOldMap != null) {
        oldContact = contactOldMap.get(c.Id);
      }
      if (c.Role__c != 'Accounts Payable' && oldContact.Role__c == 'Accounts Payable') {
        accIds.add(c.AccountId);
      }
    }
    if (accIds.size() > 0) {
      for (Account acc : [SELECT Id, AP_Contact__c FROM Account WHERE Id IN :accIds]) {
        acc.AP_Contact__c = null;
        accountsToUpdate.add(acc);
      }
      update accountsToUpdate;
    }
  }
}