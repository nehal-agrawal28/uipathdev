/**
 * @AUTHOR: UIPath
 * @DATE: 10/11/2021
 * @DESCRIPTION: The purpose of this batch class is to share account records with its Ultimate Parent Account Owner
 * SLTCHIN-956:
 * Case 1: Sharing Child Account Record with its Ultimate Parent Account Owner
 * Case 2: Sharing All Child Account Record with its Ultimate Parent Account Owner
 * Case 3: Populates KAM_GSI__c field as Ultimate Parent Account Owner Id
 * SLTCHIN-964: Populates KAM_Email__c field as Ultimate Parent Account Owner Email and send email through workflow (Workflow - Send alert to KAP Owner)
 */
public without sharing class UltimateParentAccountShare_ET implements IGenericBatch {
  // Variable Definitions
  public Set<Id> setOfUltimateParentIds = new Set<Id>();
  public Map<Id, Account> mapOfUltimateAccIdToRecord;
  public Map<Id, Account> mapOfChildAccIdToRecord = new Map<Id, Account>();
  public List<AccountShare> listOfAccountShare = new List<AccountShare>();
  public List<Account> listOfAccountsToUpdate = new List<Account>();
  public Map<String, Account> mapOfParentAccountIdToRecord = new Map<String, Account>();
  public Map<Id, List<Account>> mapOfUltimateParentAccountIdToChilds = new Map<Id, List<Account>>();

  // Implemented execute method which gets called from generic batch execute
  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    AbstractQueueable.deferEnqueue();
    setOfUltimateParentIds = new Set<Id>();
    mapOfChildAccIdToRecord = new Map<Id, Account>();
    listOfAccountShare = new List<AccountShare>();
    listOfAccountsToUpdate = new List<Account>();
    mapOfParentAccountIdToRecord = new Map<String, Account>();
    mapOfUltimateParentAccountIdToChilds = new Map<Id, List<Account>>();
    Map<Id, Account> mapOfAccountsToUpdate = new Map<Id, Account>();
    try {
      for (Account objAccount : (List<Account>) sobjectList) {
        // if the Account record is a child Account of any Parent Account then only the
        // particular child Account record will share with its Ultimate Parent Account Owner
        if (objAccount.ParentId != null) {
          if (
            !objAccount.Is_Domestic_Child__c ||
            (objAccount.Is_Domestic_Child__c && objAccount.Parent_Territory_Override__c == true)
          ) {
            setOfUltimateParentIds.add(objAccount.Ultimate_Parent_Id__c);
            mapOfChildAccIdToRecord.put(objAccount.Id, objAccount);
          }
        } else {
          // if the Account record is the Ultimate Parent Account Record which means the ParentId is NULL, then all its related
          // child record will share with this Ultimate Parent Account Owner Id
          if (!mapOfParentAccountIdToRecord.containsKey(String.valueOf(objAccount.Id).substring(0, 15))) {
            mapOfParentAccountIdToRecord.put(String.valueOf(objAccount.Id).substring(0, 15), objAccount);
          }
        }
      }

      shareChildWithUltimateParentAccount();
      shareAllUltimateParentChildswithUltimate();

      List<Database.SaveResult> result = Database.insert(listOfAccountShare, false);

      mapOfAccountsToUpdate.putAll(listOfAccountsToUpdate);

      Database.update(mapOfAccountsToUpdate.values(), false);

      Logger.debug(new LogMessage('Account Share Child Record with Ultimate Parent Account Owner', ''), result);
    } catch (Exception e) {
      Logger.error(new LogMessage('Exception: {0}', e.getLineNumber() + e.getMessage()), e);
    } finally {
      Logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext BC) {
  }

  private void shareAllUltimateParentChildswithUltimate() {
    if (mapOfParentAccountIdToRecord.KeySet().size() > 0) {
      AccountsSelector_ET accountSelector = (AccountsSelector_ET) Application_ET.Selector.newInstance(
        Account.SObjectType
      );
      // Fetching all the child accounts for all Ultimate Parent Accounts
      for (Account objAccount : accountSelector.selectByUltimateParentId(mapOfParentAccountIdToRecord.keySet())) {
        if (
          !objAccount.Is_Domestic_Child__c ||
          (objAccount.Is_Domestic_Child__c && objAccount.Parent_Territory_Override__c == true)
        ) {
          // Preparing a map where the key holds Ultimate Parent Account record Id and the values holds all its related child accounts
          if (!mapOfUltimateParentAccountIdToChilds.containsKey(objAccount.Ultimate_Parent_Id__c)) {
            mapOfUltimateParentAccountIdToChilds.put(objAccount.Ultimate_Parent_Id__c, new List<Account>{ objAccount });
          } else {
            mapOfUltimateParentAccountIdToChilds.get(objAccount.Ultimate_Parent_Id__c).add(objAccount);
          }
        }
      }
      // First Iteration is on all Ultimate Parent Account record Ids
      for (Id accountId : mapOfUltimateParentAccountIdToChilds.KeySet()) {
        // Second Iteration is on all child accounts for a single ultimate parent account
        for (Account objAccount : mapOfUltimateParentAccountIdToChilds.get(accountId)) {
          String accountId15Char = String.valueOf(accountId).substring(0, 15);
          if (mapOfParentAccountIdToRecord.containsKey(accountId15Char)) {
            Account ultimateAccount = mapOfParentAccountIdToRecord.get(accountId15Char);
            // Sharing all child accounts for a particular Ultimate Parent Account to Ultimate Parent Account Record Owner
            AccountShare accShare = new AccountShare(
              AccountId = objAccount.Id,
              AccountAccessLevel = 'Edit',
              OpportunityAccessLevel = 'Edit',
              UserOrGroupId = ultimateAccount.OwnerId
            );
            if (!listOfAccountShare.contains(accShare)) {
              listOfAccountShare.add(accShare);
            }

            if (
              objAccount.ParentId != null &&
              ultimateAccount.Classification__c == KAPClassification &&
              AccountClassifications.contains(objAccount.Classification__c)
            ) {
              // Populating KAM_GSI__c field as its Ultimate Parent Account owner id
              // and KAM_Email__c field as Ultimate Parent Account Owner Email
              listOfAccountsToUpdate.add(
                new Account(
                  Id = objAccount.Id,
                  KAM_GSI__c = ultimateAccount.OwnerId,
                  KAM_Email__c = (ultimateAccount.OwnerId != null &&
                    ultimateAccount.Owner.Email != null)
                    ? ultimateAccount.Owner.Email
                    : null
                )
              );
            }
          }
        }
      }
    }
  }

  private static String KAPClassification {
    get {
      if (KAPClassification == null) {
        ETM_Setting__mdt metadata = Utility_ET.getSetting('KAP_Classification');
        KAPClassification = metadata.Value__c;
      }
      return KAPClassification;
    }
    set;
  }

  private static List<String> AccountClassifications {
    get {
      if (AccountClassifications == null) {
        ETM_Setting__mdt metadata = Utility_ET.getSetting('Account_Classification');
        AccountClassifications = metadata.Value__c.split(',');
      }
      return AccountClassifications;
    }
    set;
  }

  private void shareChildWithUltimateParentAccount() {
    if (mapOfChildAccIdToRecord.KeySet().size() > 0) {
      AccountsSelector_ET accountSelector = (AccountsSelector_ET) Application_ET.Selector.newInstance(
        Account.SObjectType
      );
      mapOfUltimateAccIdToRecord = new Map<Id, Account>(accountSelector.selectById(setOfUltimateParentIds));
      for (Id childAccountId : mapOfChildAccIdToRecord.KeySet()) {
        Account childAccount = mapOfChildAccIdToRecord.containsKey(childAccountId)
          ? mapOfChildAccIdToRecord.get(childAccountId)
          : null;
        if (
          childAccount.Ultimate_Parent_Id__c != null &&
          mapOfUltimateAccIdToRecord.containsKey(childAccount.Ultimate_Parent_Id__c)
        ) {
          Account ultimateAccount = mapOfUltimateAccIdToRecord.get(childAccount.Ultimate_Parent_Id__c);
          // Sharing a particular child account record with its Ultimate Parent Account Owner
          AccountShare accShare = new AccountShare(
            AccountId = childAccountId,
            AccountAccessLevel = 'Edit',
            OpportunityAccessLevel = 'Edit',
            UserOrGroupId = ultimateAccount.OwnerId
          );
          if (!listOfAccountShare.contains(accShare)) {
            listOfAccountShare.add(accShare);
          }
          // populating KAM_GSI__c field as its ultimate parent account Owner and
          // KAM_Email__c field as Ultimate Account Owner Email Address
          if (
            childAccount.Classification__c == KAPClassification &&
            AccountClassifications.contains(ultimateAccount.Classification__c)
          ) {
            listOfAccountsToUpdate.add(
              new Account(
                Id = childAccountId,
                KAM_GSI__c = ultimateAccount.OwnerId,
                KAM_Email__c = (ultimateAccount.OwnerId != null &&
                  ultimateAccount.Owner.Email != null)
                  ? ultimateAccount.Owner.Email
                  : null
              )
            );
          }
        }
      }
    }
  }
}