/**
 * This batch will work for the below cases
 * 1. When the Primary Account Manager on the associated Territory is changed
 * 2. When an Interim Account Manager becomes active on the Territory (Primary removed or set to temporary absence)
 * 3. On new Opportunity records where there is a discrepancy between the creator and the Primary account manager of the territory assigned by the default logic
 * 4. When the Opportunity Territory has been updated
 */
public without sharing class OpportunityOwnerSyncBatch_ET implements IGenericBatch {
  public List<Opportunity> listOfExceptionOpportunities = new List<Opportunity>();
  public Set<Id> exceptionOppIds = new Set<Id>();
  public dateTime lastRunDateTime;

  public void execute(Database.BatchableContext BC, List<Sobject> sobjectList) {
    // disable CPQ triggers
    SBQQ.TriggerControl.disable();

    // Defer Queueable
    AbstractQueueable.deferEnqueue();
    List<Opportunity> opportunityList = (List<Opportunity>) sobjectList;
    OpportunitiesService_ET service = (OpportunitiesService_ET) Application_ET.Service.newInstance(
      OpportunitiesService_ET.class
    );
    listOfExceptionOpportunities = service.syncOpportunityOwner(opportunityList, true);
    OpportunityCompensationService_ET compService = (OpportunityCompensationService_ET) Application_ET.Service.newInstance(
      OpportunityCompensationService_ET.class
    );

    exceptionOppIds.addAll(compService.syncOpportunitySplit(opportunityList));
  }

  public void finish(Database.BatchableContext BC) {
    Skip_Email_Alerts__c skipEmailAlert = Skip_Email_Alerts__c.getInstance();
    if (skipEmailAlert != null && !skipEmailAlert.Skip_Email_Alerts_Opportunity__c) {
      OpportunitiesSelector_ET oppSelector = (OpportunitiesSelector_ET) Application_ET.Selector.newInstance(
        Opportunity.SObjectType
      );

      ETMSystemNotificationService etmSystem = new ETMSystemNotificationService();
      etmSystem.opportunityOwnerSyncException(listOfExceptionOpportunities);
      etmSystem.oppPartnerTerritoryException(oppSelector.selectOppById(exceptionOppIds));
    }
  }
}