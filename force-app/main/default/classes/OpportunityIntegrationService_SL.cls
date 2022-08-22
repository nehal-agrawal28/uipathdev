/**
 * Created by roxana.anghel on 1/9/2021.
 * Just a bunch of Static Utility methods - each publishing Opportunities, and related objects upon opportunity changes
 * to the UiPath Orchestrator in specific circumstances
 * These methods have been separated into this class to keep the domains small and readable
 */
public with sharing class OpportunityIntegrationService_SL {
  public static void publishClosedWonBookedOpps(List<SObject> records, Map<Id, SObject> existingRecords) {
    OrchestratorNotifierQueueable.beginSetup(records, Constants_SL.OPP_CW_NOTIFICATION_SF_CONNECTOR_TEMPLATE)
      .withFilterConditions(
        Match.field(Opportunity.StageName).isIn(new Set<String>{ Constants_SL.OPPORTUNITY_STAGE_WON })
      )
      .withFieldsToCheckForChange(new Set<SObjectField>{ Opportunity.StageName })
      .withOldRecords(existingRecords)
      .endSetup()
      .publishUpdatedRecords();
  }

  public static void publishLeadSalesEngineer(List<SObject> records, Map<Id, SObject> existingRecords) {
    OrchestratorNotifierQueueable.beginSetup(records, Constants_SL.LEAD_SALES_ENGINEER_TEMPLATE)
      .withFilterConditions(
        Match.field(Opportunity.Probability)
          .greaterThanOrEquals(25)
          .also(Opportunity.IsClosed)
          .equals(false)
          .also(Opportunity.Type)
          .isIn(
            new Set<String>{
              Constants_SL.OPPORTUNITY_TYPE_UPSELL,
              Constants_SL.OPPORTUNITY_TYPE_RENEWAL,
              Constants_SL.OPPORTUNITY_TYPE_NEW_BUSINESS
            }
          )
          .also(Opportunity.Lead_Sales_Engineer__c)
          .equals(null)
      )
      .withFieldsToCheckForChange(
        new Set<SObjectField>{ Opportunity.Lead_Sales_Engineer__c, Opportunity.Type, Opportunity.StageName }
      )
      .withOldRecords(existingRecords)
      .endSetup()
      .publishUpdatedRecords();
  }
}