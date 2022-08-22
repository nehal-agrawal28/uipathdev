public class CaseValidateRiskFunction_SL implements SObjectToSObjectFunction {
  private static final String ERROR_MESSAGE =
    'D&B database is currently interrogated, it can take up to 10min for the credit check to be completed. ' +
    'For any issues, you can contact credit@uipath.com';

  private Map<Id, SBQQ__Quote__c> quotes;
  private Map<Id, Opportunity> closedWonOpps;
  public CaseValidateRiskFunction_SL(List<Case> records) {
    List<Id> quoteIds = Collection.of(records).pluckIds(Case.Primary_Quote__c);
    this.quotes = new Map<Id, SBQQ__Quote__c>(
      [
        SELECT
          Id,
          Bill_To_Account__c,
          Bill_To_Account__r.Risk_Category__c,
          Bill_To_Account__r.won_opportunities__c,
          SBQQ__Opportunity2__c
        FROM SBQQ__Quote__c
        WHERE
          Id IN :quoteIds
          AND SBQQ__Primary__c = TRUE
          AND SBQQ__Opportunity2__r.StageName NOT IN (
            :OpportunityMetadata_SL.CLOSED_WON_PENDING,
            :OpportunityMetadata_SL.CLOSED_WON_BOOKED
          )
      ]
    );

    List<Id> billToIds = Collection.of(this.quotes.values()).pluckIds(SBQQ__Quote__c.Bill_To_Account__c);

    this.closedWonOpps = new Map<Id, Opportunity>(
      [
        SELECT Id, StageName
        FROM Opportunity
        WHERE
          SBQQ__PrimaryQuote__r.Bill_To_Account__c IN :billToIds
          AND StageName IN (:OpportunityMetadata_SL.CLOSED_WON_PENDING, :OpportunityMetadata_SL.CLOSED_WON_BOOKED)
      ]
    );
  }

  public SObject apply(Case record) {
    SBQQ__Quote__c quote = quotes.get(record.Primary_Quote__c);
    if (quote != null) {
      Opportunity closedWonOpp = closedWonOpps.get(quote.SBQQ__Opportunity2__c);
      if (closedWonOpp == null) {
        if (
          quote.Bill_To_Account__r.Risk_Category__c == null ||
          quote.Bill_To_Account__r.Risk_Category__c == 'In Progress'
        ) {
          record.addError(ERROR_MESSAGE);
        }
      }
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void checkRiskCategory(List<SObject> records, Map<Id, SObject> existingRecords) {
    HasRecordChanged hasChanged = new HasRecordChanged(new Set<SObjectField>{ Case.Status }, records, existingRecords);

    Collection.of(records)
      .filter(hasChanged)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(new Set<Id>{ CaseMetadata_SL.FinanceRequestRecordType })
          .also(Case.Status)
          .isIn(new Set<String>{ CaseMetadata_SL.FINANCE_REVIEW })
      )
      .mapSome(Match.field(Case.Primary_Quote__c).hasValue(), new CaseValidateRiskFunction_SL(records));
  }
}