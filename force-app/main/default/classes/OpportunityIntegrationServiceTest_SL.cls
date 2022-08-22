/**
 * Created by roxana.anghel on 1/9/2021.
 */
@IsTest(IsParallel=false)
public with sharing class OpportunityIntegrationServiceTest_SL {
  @TestSetup
  static void makeData() {
    Account account = DataFactory_CM.createAccounts(AccountMetadata.customerProspectRecordType, 2, true).get(0);
  }

  @IsTest
  public static void publishClosedWonBookedOpps() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, true);
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opportunity.Id, true);

    opportunity.SBQQ__PrimaryQuote__c = quote.Id;
    opportunity.FinanceReviewReached__c = true;
    opportunity.StageName = 'Closed Won Booked';

    OrchestratorNotifierQueueable.forceSyncMode = true;
    update opportunity;

    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();

    for (UiPath__UiPathLog__c log : [
      SELECT Id, UiPath__Details__c
      FROM UiPath__UiPathLog__c
      WHERE CreatedDate = TODAY
    ]) {
      if (log.Uipath__Details__c.contains(Constants_SL.OPP_CW_NOTIFICATION_SF_CONNECTOR_TEMPLATE)) {
        logList.add(log);
      }
    }

    System.assertEquals(true, !logList.isEmpty(), 'There should be at least 1 publish attempt in the logs');
  }

  @IsTest
  public static void publishLeadSalesEngineer() {
    Account account = [SELECT Id FROM Account LIMIT 1];
    Opportunity opportunity = DataFactory_SL.createOpportunity(account.Id, true);
    opportunity.Type = Constants_SL.OPPORTUNITY_TYPE_RENEWAL;
    opportunity.StageName = Constants_SL.OPPORTUNITY_STAGE_PROPOSAL;
    OrchestratorNotifierQueueable.forceSyncMode = true;
    update opportunity;
    List<UiPath__UiPathLog__c> logList = new List<UiPath__UiPathLog__c>();
    for (UiPath__UiPathLog__c log : [
      SELECT Id, UiPath__Details__c
      FROM UiPath__UiPathLog__c
      WHERE CreatedDate = TODAY
    ]) {
      if (log.Uipath__Details__c.contains(Constants_SL.LEAD_SALES_ENGINEER_TEMPLATE)) {
        logList.add(log);
      }
    }

    System.assertEquals(true, !logList.isEmpty(), 'There should be at least 1 publish attempt in the logs');
  }
}