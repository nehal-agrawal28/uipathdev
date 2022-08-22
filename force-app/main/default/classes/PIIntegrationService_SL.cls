/**
 * Created by roxana.anghel on 1/25/2021.
 */

public with sharing class PIIntegrationService_SL {
  /**
   * Sends new Accounts to Netsuite
   * @param records inserted items
   */
  public static void publishToUiPathConnector(List<SObject> records) {
    OrchestratorNotifierQueueable.beginSetup(records, Constants.MICROSOFT_PARTNER_INVOLVEMENT_UIPATH_CONNECTOR_TEMPLATE)
      .withFilterConditions(
        Match.field(Partner_Involvement__c.Partner_Name_Text__c)
          .isIn(new Set<String>{ PartnerInvolvementMetadata_SL.MICROSOFT_CORP_TECH_ALLIANCE })
          .also(Partner_Involvement__c.Partner_Sales_Role__c)
          .equals(PartnerInvolvementMetadata_SL.CO_SELL_PARTNER_ROLE)
      )
      .endSetup()
      .publishNewRecords();
  }
}