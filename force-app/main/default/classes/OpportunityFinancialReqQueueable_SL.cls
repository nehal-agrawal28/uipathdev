public with sharing class OpportunityFinancialReqQueueable_SL extends AbstractQueueable {
  private final List<SObject> opps;
  @testVisible
  private boolean hasRun = false;

  public OpportunityFinancialReqQueueable_SL(List<SObject> opps) {
    super('OpportunityFinancialReqQueueable_SL');
    this.opps = opps;
    //to allow for logging against record. only used in non-bulk contexts
    if (opps != null && opps.size() == 1) {
      this.setPrimaryRecordId(opps.get(0).Id);
    }
  }

  public override void work() {
    if (hasRun) {
      return;
    }
    this.createCasesFromOpps(this.opps);
  }

  private void createCasesFromOpps(List<Opportunity> opps) {
    List<Case> financialCases = new List<Case>();

    for (Opportunity opp : [
      SELECT
        Id,
        AccountId,
        Cancellation_Transaction__c,
        Account.won_opportunities__c,
        Account.Risk_Category__c,
        CurrencyIsoCode,
        JP_Campaign__c,
        OwnerId,
        Partner__c,
        Send_invoice_to__c,
        Send_licenses_to__c,
        Replacement_Transaction__c,
        Reseller__c,
        Sold_to_Partner__c,
        SBQQ__PrimaryQuote__c,
        SBQQ__PrimaryQuote__r.SBQQ__ListAmount__c,
        (
          SELECT Id, CaseNumber, RecordType.Name
          FROM Cases__r
          WHERE RecordTypeId = :CaseMetadata_SL.FinanceRequestRecordType
        )
      FROM Opportunity
      WHERE Id IN :opps
    ]) {
      if (opp.Cases__r.isEmpty()) {
        Case financialCase = new Case();
        financialCase.AccountId = opp.AccountId;
        financialCase.CurrencyIsoCode = opp.CurrencyIsoCode;
        financialCase.Document_Type__c = 'Invoice';
        financialCase.JP_Campaign__c = opp.JP_Campaign__c;
        financialCase.Opportunity_Owner_Lookup__c = opp.OwnerId;
        financialCase.Opportunity__c = opp.Id;
        financialCase.OwnerId = OpportunityMetadata_SL.FinanceCaseOwnerId;
        financialCase.Partner__c = opp.Partner__c;
        financialCase.RecordTypeId = CaseMetadata_SL.FinanceRequestRecordType;
        financialCase.Send_invoice_to__c = opp.Send_invoice_to__c;
        financialCase.Send_licenses_to_email__c = opp.Send_licenses_to__c;
        financialCase.Status = CaseMetadata_SL.DEAL_HUB_REVIEW;
        financialCase.Subject = CaseMetadata_SL.PLEASE_INVOICE;
        financialCase.Reseller__c = opp.Sold_to_Partner__c;
        determineRipReplaceContext(opp, financialCase);
        financialCases.add(financialCase);
      }
    }
    if (financialCases.isEmpty()) {
      return;
    }
    insert financialCases;
    hasRun = true;
  }

  /**
   * @description for a given opportunity and case, determine the rip and replace
   * context for the case
   * @param opp the opportunity spawning the financial case
   * @param financialCase the financial case to be manipulated
   */
  @TestVisible
  private static void determineRipReplaceContext(Opportunity opp, Case financialCase) {
    financialCase.Cancellation_Transaction__c = opp.Cancellation_Transaction__c;
    financialCase.Replacement_Transaction__c = opp.Replacement_Transaction__c;
  }

  /**
   * Create financial Case on update
   */
  public static void createCases(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{
        Opportunity.StageName,
        Opportunity.Deal_Type__c,
        Opportunity.CurrencyIsoCode,
        Opportunity.SBQQ__PrimaryQuote__c
      },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.StageName)
          .equals('Closed Won Pending')
          .also(Opportunity.Deal_Type__c)
          .notIn(new Set<String>{ 'Public Preview', 'NFR', 'COVID-19 Solidarity', 'Humanitarian Aid' })
          .also(Opportunity.CurrencyIsoCode)
          .notEquals('JPY')
          .also(Opportunity.SBQQ__PrimaryQuote__c)
          .notEquals(null)
      )
      .asList();

    if (!changedOpps.isEmpty()) {
      AbstractQueueable.enqueue(new OpportunityFinancialReqQueueable_SL(changedOpps));
    }
  }
}