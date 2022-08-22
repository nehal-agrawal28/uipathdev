public with sharing class OpportunityFinancialReqJPQueueable_SL extends AbstractQueueable {
  private final List<SObject> opps;
  private boolean hasRun = false;
  Id defaultBusinessHours;
  Id JPBusinessHours;

  public OpportunityFinancialReqJPQueueable_SL(List<SObject> opps) {
    super('OpportunityFinancialReqJPQueueable_SL');
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
    //need another solution here, maybe adding the BHs to data/businesshours.json?
    for (BusinessHours bh : [SELECT Id, Name FROM BusinessHours WHERE Name = 'Bucharest' OR IsDefault = TRUE]) {
      if (bh.Name == 'Bucharest') {
        JPBusinessHours = bh.Id;
      } else {
        defaultBusinessHours = bh.Id;
      }
    }
    Financial_Request_Owners__c froSetting = [SELECT Id, Case_Owner__c FROM Financial_Request_Owners__c LIMIT 1];

    List<Case> financialCases = new List<Case>();

    for (Opportunity opp : [
      SELECT
        Id,
        AccountId,
        Cancellation_Transaction__c,
        CurrencyIsoCode,
        JP_Campaign__c,
        OwnerId,
        Sold_to_Partner__c,
        Included_in_Partner_Community__c,
        Replacement_Transaction__c,
        Contact_Street_Address__r.Id,
        (
          SELECT Id, CaseNumber, RecordType.Name
          FROM Cases__r
          WHERE RecordTypeId = :CaseMetadata_SL.FinanceRequestRecordType
        )
      FROM Opportunity
      WHERE Id IN :opps
    ]) {
      if (!opp.Cases__r.isEmpty()) {
        continue;
      }
      Case financialCase = new Case();
      if (Test.isRunningTest()) {
        financialCase.BusinessHoursId = defaultBusinessHours;
      } else {
        financialCase.BusinessHoursId = JPBusinessHours;
      }
      financialCase.AccountId = opp.AccountId;
      financialCase.CurrencyIsoCode = opp.CurrencyIsoCode;
      financialCase.Document_Type__c = 'Invoice';
      financialCase.JP_Campaign__c = opp.JP_Campaign__c;
      financialCase.Opportunity_Owner_Lookup__c = opp.OwnerId;
      financialCase.Opportunity__c = opp.Id;
      financialCase.OwnerId = froSetting.Case_Owner__c;
      financialCase.RecordTypeId = CaseMetadata_SL.FinanceRequestRecordType;
      financialCase.Reseller__c = opp.Sold_to_Partner__c;
      financialCase.Status = CaseMetadata_SL.DEAL_HUB_REVIEW;
      financialCase.Subject = CaseMetadata_SL.PLEASE_INVOICE;
      determineRipReplaceContext(opp, financialCase);
      financialCases.add(financialCase);
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
   * Create financial Case on update for Japanese Opportunity
   */
  public static void createCases(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{
        Opportunity.StageName,
        Opportunity.CurrencyIsoCode,
        Opportunity.Included_in_Partner_Community__c
      },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.StageName).equals('Closed Won Pending').also(Opportunity.CurrencyIsoCode).equals('JPY')
      )
      .asList();

    if (!changedOpps.isEmpty()) {
      AbstractQueueable.enqueue(new OpportunityFinancialReqJPQueueable_SL(changedOpps));
    }
  }
}