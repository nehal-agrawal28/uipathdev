/**
 * @AUTHOR: UIPath
 * @DATE: 01/10/2021
 * @DESCRIPTION: This is TerritoryAccountOwnerSyncBatch class
 */
public class TerritoryAccountOwnerSyncBatch_ET implements IGenericBatch {
  public Set<Id> setOfExceptionAccountIds = new Set<Id>();
  public Set<Id> exceptionOppIds = new Set<Id>();
  public Set<Id> setOfTerritory2Ids = new Set<Id>();

  // Implemented execute method which gets called from generic batch execute
  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    Set<Id> accountIds = new Set<Id>();
    List<ObjectTerritory2Association> objAssociationList = (List<ObjectTerritory2Association>) sobjectList;
    for (ObjectTerritory2Association objAssociation : objAssociationList) {
      accountIds.add(objAssociation.ObjectId);
    }

    for (ObjectTerritory2Association OTA : objAssociationList) {
      setOfTerritory2Ids.add(OTA.Territory2Id);
    }

    AccountsService_ET service = (AccountsService_ET) Application_ET.Service.newInstance(AccountsService_ET.class);
    Skip_Email_Alerts__c skipEmailAlert = Skip_Email_Alerts__c.getInstance();
    List<Account> accountList = service.syncAccountOwner(accountIds);
    if (skipEmailAlert != null && !skipEmailAlert.Skip_Email_Alerts_Account__c) {
      for (Account objAccount : accountList) {
        if (objAccount.Owner_Sync_Status__c == ETMConstant.OWNER_STATUS_EXCEPTION) {
          setOfExceptionAccountIds.add(objAccount.Id);
        }
      }
    }

    //Opportunity Split Recalculate Call
    OpportunitiesSelector_ET oppSelector = (OpportunitiesSelector_ET) Application_ET.Selector.newInstance(
      Opportunity.SObjectType
    );
    List<Opportunity> opportunityList = oppSelector.selectCompOpportunities(accountIds);
    OpportunityCompensationService_ET compService = (OpportunityCompensationService_ET) Application_ET.Service.newInstance(
      OpportunityCompensationService_ET.class
    );
    exceptionOppIds.addAll(compService.syncOpportunitySplit(opportunityList));
  }

  public void finish(Database.BatchableContext BC) {
    Skip_Email_Alerts__c skipEmailAlert = Skip_Email_Alerts__c.getInstance();
    if (skipEmailAlert != null && !skipEmailAlert.Skip_Email_Alerts_Account__c) {
      AccountsSelector_ET accountSelector = (AccountsSelector_ET) Application_ET.Selector.newInstance(
        Account.SObjectType
      );
      ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
      etmSystem.accountOwnerSyncException(accountSelector.selectById(setOfExceptionAccountIds));
    }
    if (skipEmailAlert != null && !skipEmailAlert.Skip_Email_Alerts_Opportunity__c) {
      // Sending Emails for Exception ones
      OpportunitiesSelector_ET exceptionoppSelector = (OpportunitiesSelector_ET) Application_ET.Selector.newInstance(
        Opportunity.SObjectType
      );
      ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
      etmSystem.oppPartnerTerritoryException(exceptionoppSelector.selectOppById(exceptionOppIds));
    }
    // Territory2 is a setup object, therefore calling TerritoryQueueable_ET queuable class to reset Recalculate Compensation flag
    AbstractQueueable.enqueue(new TerritoryQueueable_ET(setOfTerritory2Ids, false));
  }
}