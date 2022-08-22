public without sharing class CaseFinanceIntegrationService_SL {
  public static void publishToUiPathConnector(List<Case> records) {
    List<Case> filteredRecords = (List<Case>) Collection.of(records)
      .filter(
        Match.field(Case.RecordTypeId)
          .equals(CaseMetadata_SL.FinanceRequestRecordType)
          .also(Case.Status)
          .equals(CaseMetadata_SL.DEAL_HUB_REVIEW)
          .also(Case.Subject)
          .equals(CaseMetadata_SL.PLEASE_INVOICE)
          .also(Case.Opportunity__c)
          .hasValue()
      )
      .asList();

    if (filteredRecords.isEmpty()) {
      return;
    }
    List<Id> opportunityIds = Collection.of(filteredRecords).pluckIds(Case.Opportunity__c);
    if (canBePublished(opportunityIds)) {
      OrchestratorNotifierQueueable.beginSetup(filteredRecords, Constants_SL.FINANCE_CASE_TEMPLATE)
        .endSetup()
        .publishNewRecords();
    }
  }

  public static Boolean canBePublished(List<Id> opportunityIds) {
    List<SBQQ__Quote__c> pimaryQuotes = [
      SELECT Bill_To_Account__c
      FROM SBQQ__Quote__c
      WHERE
        SBQQ__Opportunity2__c = :opportunityIds
        AND Bill_To_Account__r.Risk_Category__c = NULL
        AND SBQQ__Primary__c = TRUE
    ];
    if (pimaryQuotes.isEmpty()) {
      return false;
    }
    List<Id> billToAccountIds = Collection.of(pimaryQuotes).pluckIds(SBQQ__Quote__c.Bill_To_Account__c);
    List<Opportunity> closedWonOpps = [
      SELECT Id, StageName
      FROM Opportunity
      WHERE
        SBQQ__PrimaryQuote__r.Bill_To_Account__c IN :billToAccountIds
        AND StageName IN (:OpportunityMetadata_SL.CLOSED_WON_PENDING, :OpportunityMetadata_SL.CLOSED_WON_BOOKED)
        AND Id NOT IN :opportunityIds
    ];

    if (closedWonOpps.isEmpty()) {
      List<Partner_Involvement__c> existingClosedPartners = [
        SELECT Id
        FROM Partner_Involvement__c
        WHERE
          Partner_Account_Name__c IN :billToAccountIds
          AND PartnerOpp_Name__c NOT IN :opportunityIds
          AND PartnerOpp_Name__r.StageName IN (:OpportunityMetadata_SL.CLOSED_WON_BOOKED)
      ];
      if (existingClosedPartners.isEmpty()) {
        return true;
      }
    }
    return false;
  }
}