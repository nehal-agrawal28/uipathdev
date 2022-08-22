/*
@Who    Daniel Edwards (Slalom)
@What   Batch class to keep Lead OwnerId in sync with the related Account's (lead.Account__c) Territory2 EDR, otherwise
use the primary / interim account manager
@when   26/10/2021
*/
public class LeadOwnerSyncBatch implements Database.Batchable<sObject>, System.Schedulable {
  private List<String> queryStatusFilter, territoryRolesForOwnership; // Query filters used on line 69
  private integer minutesFromNowToRunBatch; // The number of minutes to wait before running the batch class again on line 99
  private Id leadStandartRecType;
  /**
   * Init
   */
  {
    queryStatusFilter = new List<String>{ 'MQL', 'Accepted' };
    leadStandartRecType = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
    territoryRolesForOwnership = new List<String>{
      'Enterprise Development Rep',
      'Sales Development Rep',
      'Primary Account Manager'
    };

    minutesFromNowToRunBatch = 10;
  }

  /**
   * start ()
   * --
   *
   * The first stage of the batch class, return the Lead records that meet criteria
   */
  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(
      'SELECT Id, OwnerId, Account__c, Territory_Id__c FROM Lead WHERE RecordTypeId = :leadStandartRecType AND Status IN :queryStatusFilter AND Account__c != null'
    );
  }

  /**
   * execute ()
   * --
   *
   * The entry point for running the batch class from a schedule
   */
  public void execute(System.SchedulableContext sc) {
    Database.executeBatch(new LeadOwnerSyncBatch());
  }

  /**
   * execute ()
   * --
   *
   * Process each batch of records returned by start ();
   */
  public void execute(Database.BatchableContext bc, List<sObject> scope) {
    try {
      // Store each Id from the Account__c field so we can read the Territory2 information from the related Account
      Set<Id> accountIds = new Set<Id>();
      Map<Id, Id> mapOfAccIdToTerr2Id = new Map<Id, Id>();
      for (Lead recordContext : (List<Lead>) scope)
        if ((String.valueOf(recordContext.OwnerId)).startsWith('005') && !accountIds.contains(recordContext.Account__c))
          accountIds.add(recordContext.Account__c);

      // Stop if no Account__c Ids are found
      if (accountIds.isEmpty())
        return;

      ObjectTerritory2AssociationsSelector_ET objAssociationSelector = (ObjectTerritory2AssociationsSelector_ET) Application_ET.Selector.newInstance(
        ObjectTerritory2Association.getSObjectType()
      );

      for (ObjectTerritory2Association OTA : objAssociationSelector.selectByObjectId(accountIds)) {
        if (!mapOfAccIdToTerr2Id.containsKey(OTA.ObjectId)) {
          mapOfAccIdToTerr2Id.put(OTA.ObjectId, OTA.Territory2Id);
        }
      }

      // Return related Territory info from the collected Ids from the Account__c field
      Type accTerritoryTypeInstance = Type.forName('AccountsService_ET');
      IAccountTerritory accountTerritory = (IAccountTerritory) accTerritoryTypeInstance.newInstance();
      Map<Id, Territory2> mapOfAccountIdToTerritory2 = accountTerritory.getAccountPrimarySalesTerritory(accountIds);

      if (mapOfAccountIdToTerritory2.isEmpty())
        return;

      // For each returned Territory2, get the Id to use to return the Users assigned to the Territory2 records
      Set<Id> territoryIds = new Set<Id>();
      Set<Id> setOfPAMTerritory2Ids = new Set<Id>();
      for (Territory2 tr : mapOfAccountIdToTerritory2.values())
        territoryIds.add(tr.Id);

      if (territoryIds.isEmpty())
        return;

      Map<Id, Id> mapOfTerritory2IdToUserId = new Map<Id, Id>();
      for (UserTerritory2Association objUserTerrAssociation : [
        SELECT Id, Territory2Id, RoleInTerritory2, UserId
        FROM UserTerritory2Association
        WHERE Territory2Id IN :territoryIds AND RoleInTerritory2 IN :territoryRolesForOwnership
      ]) {
        if (objUserTerrAssociation.RoleInTerritory2 == ETMConstant.PRIMARY_ACCOUNT_MANAGER) {
          setOfPAMTerritory2Ids.add(objUserTerrAssociation.Territory2Id);
        }
        if (
          objUserTerrAssociation.RoleInTerritory2 == ETMConstant.ENTERPRISE_DEVELOPMENT_REP ||
          objUserTerrAssociation.RoleInTerritory2 == ETMConstant.SALES_DEVELOPMENT_REP
        ) {
          if (!mapOfTerritory2IdToUserId.containsKey(objUserTerrAssociation.Territory2Id)) {
            mapOfTerritory2IdToUserId.put(objUserTerrAssociation.Territory2Id, objUserTerrAssociation.UserId);
          }
        }
      }
      // First it will check if the Account has any Territory with Roles: Enterprise Development Rep/Sales Development Rep then the lead owner should be the user from that roles, if there are no roles exist then
      // Second it will check if the Account has any Territory with Role: Primary Account Manager then the lead owner should be the user from Primary Account Manager, if no Primary Account Manager exist then
      // Third it will check if the Account has any Territory with Role: Interim Account Manager then the lead owner should be the user from Interim Account Manager
      List<Lead> leadToUpdate = new List<Lead>();
      for (Lead objLead : (List<Lead>) scope) {
        if ((String.valueOf(objLead.OwnerId)).startsWith('005')) {
          Territory2 objTerritory = mapOfAccountIdToTerritory2.KeySet().size() > 0
            ? mapOfAccountIdToTerritory2.get(objLead.Account__c)
            : null;

          if (mapOfTerritory2IdToUserId.containsKey(mapOfAccIdToTerr2Id.get(objLead.Account__c))) {
            objLead.OwnerId = mapOfTerritory2IdToUserId.get(mapOfAccIdToTerr2Id.get(objLead.Account__c));
          } else if (
            objTerritory != null &&
            objTerritory.Primary_Account_Manager_Id__c != null &&
            setOfPAMTerritory2Ids.contains(objTerritory.Id)
          ) {
            objLead.OwnerId = objTerritory.Primary_Account_Manager_Id__c;
          } else if (objTerritory != null && objTerritory.Interim_Account_Manager_Id__c != null) {
            objLead.OwnerId = objTerritory.Interim_Account_Manager_Id__c;
          }
          leadToUpdate.add(objLead);
        }
      }
      List<Database.SaveResult> result = Database.update(leadToUpdate, false);
      Logger.debug(new LogMessage('Lead Owner Update Result', ''), result);
    } catch (Exception e) {
      Logger.error(new LogMessage('Exception: {0}', e.getLineNumber() + e.getMessage()));
    } finally {
      Logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext bc) {
    // Schedule the batch to run x minutes from now
    if (!Test.isRunningTest())
      System.scheduleBatch(new LeadOwnerSyncBatch(), 'LeadOwnerSyncBatch', minutesFromNowToRunBatch);
  }
}