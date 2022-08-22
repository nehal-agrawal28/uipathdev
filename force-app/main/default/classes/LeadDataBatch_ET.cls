public without sharing class LeadDataBatch_ET implements IGenericBatch {
  /**
   * execute ()
   * --
   *
   * Process each batch of records returned by start ();
   */
  public void execute(Database.BatchableContext bc, List<Sobject> sobjectList) {
    // Store each Id from the Account__c field so we can read the Territory2 information from the related Account
    system.debug('sobjectList' + sobjectList);
    Set<Id> accountIds = new Set<Id>();
    for (Lead recordContext : (List<Lead>) sobjectList) {
      if (!accountIds.contains(recordContext.Account__c)) {
        accountIds.add(recordContext.Account__c);
      }
    }

    // Stop if no Account__c Ids are found
    if (accountIds.isEmpty()) {
      return;
    }

    // Return related Territory info from the collected Ids from the Account__c field
    Type accTerritoryTypeInstance = Type.forName('AccountsService_ET');
    IAccountTerritory accountTerritory = (IAccountTerritory) accTerritoryTypeInstance.newInstance();
    Map<Id, Territory2> mapOfAccountIdToTerritory2 = accountTerritory.getAccountPrimarySalesTerritory(accountIds);
    system.debug('mapOfAccountIdToTerritory21' + mapOfAccountIdToTerritory2);
    List<String> territoryRolesForOwnership = new List<String>{ 'Enterprise Development Rep', 'Sales Development Rep' };

    if (mapOfAccountIdToTerritory2.isEmpty()) {
      return;
    }

    // For returned Territory2, get the Id to use to return the Users assigned to the Territory2 records
    Set<Id> territoryIds = new Set<Id>();
    Set<Id> setOfPAMTerritory2Ids = new Set<Id>();
    for (Territory2 tr : mapOfAccountIdToTerritory2.values()) {
      territoryIds.add(tr.Id);
    }

    Map<Id, Id> territoryId_userId = new Map<Id, Id>();

    if (!territoryIds.isEmpty()) {
      for (UserTerritory2Association recordContext : [
        SELECT Id, Territory2Id, UserId
        FROM UserTerritory2Association
        WHERE Territory2Id IN :territoryIds AND RoleInTerritory2 IN :territoryRolesForOwnership
      ]) {
        if (!territoryId_userId.containsKey(recordContext.Territory2Id)) {
          territoryId_userId.put(recordContext.Territory2Id, recordContext.UserId);
        }
      }
    }

    try {
      for (Lead lead : (List<Lead>) sobjectList) {
        Territory2 objTerritory = mapOfAccountIdToTerritory2.KeySet().size() > 0
          ? mapOfAccountIdToTerritory2.get(lead.Account__c)
          : null;

        // Assign territory info
        if (objTerritory != null) {
          lead.Territory_Id__c = objTerritory.Id;
          lead.Territory_Name__c = objTerritory.Name;
          lead.Geo__c = objTerritory.Ultimate_Geo__c;
          lead.Area__c = objTerritory.Area__c;
          lead.Region_Text__c = objTerritory.Region__c;

          system.debug('territoryId_userId' + territoryId_userId);
          // Assign new Lead Owner
          if (territoryId_userId.containsKey(lead.Territory_Id__c)) {
            lead.OwnerId = territoryId_userId.get(lead.Territory_Id__c);
          } else if (objTerritory.Primary_Account_Manager_Id__c != null) {
            lead.OwnerId = objTerritory.Primary_Account_Manager_Id__c;
          } else if (objTerritory.Interim_Account_Manager_Id__c != null) {
            lead.OwnerId = objTerritory.Interim_Account_Manager_Id__c;
          }
        }
      }
      LeadTriggerAllHandler.skipLeadTriggerHandler = true;

      List<Database.SaveResult> result = Database.update(sobjectList, false);

      Logger.debug(new LogMessage('Updated Lead Result', ''), result);
    } catch (Exception e) {
      Logger.error(new LogMessage('Exception: {0}', e.getLineNumber() + e.getMessage()));
    } finally {
      Logger.saveLog();
    }
  }

  public void finish(Database.BatchableContext bc) {
    Logger.saveLog();
  }
}