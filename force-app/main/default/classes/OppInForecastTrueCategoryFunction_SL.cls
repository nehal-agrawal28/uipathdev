public inherited sharing class OppInForecastTrueCategoryFunction_SL implements SObjectToSObjectFunction {
  public SObject apply(Opportunity opp) {
    opp.In_Forecast__c = true;
    return opp;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public class ForecastCategoryNameChanged implements SObjectPredicate {
    Map<Id, SObject> changedRecords = new Map<Id, SObject>();

    public ForecastCategoryNameChanged(
      Set<Schema.SObjectField> fieldTokens,
      List<SObject> records,
      Map<Id, SObject> existingRecords
    ) {
      for (SObject newRecord : Records) {
        Id recordId = (Id) newRecord.get('Id');
        if (existingRecords == null || !existingRecords.containsKey(recordId)) {
          continue;
        }
        SObject oldRecord = existingRecords.get(recordId);
        for (Schema.SObjectField fieldToken : fieldTokens) {
          if (
            fieldToken == Opportunity.ForecastCategoryName &&
            (newRecord.get(fieldToken) == 'Best Case' ||
            oldRecord.get(fieldToken) == 'Commit')
          ) {
            if (oldRecord.get(fieldToken) != newRecord.get(fieldToken)) {
              changedRecords.put(newRecord.Id, newRecord);
              break; // prevents the records from being added multiple times
            }
          }
        }
      }
    }

    public Boolean apply(SObject record) {
      return changedRecords.containsKey(record.Id);
    }
  }

  /**
   */
  public static void deriveUpsideForecastOnUpdate(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new ForecastCategoryNameChanged(
      new Set<SObjectField>{ Opportunity.ForecastCategoryName },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.ForecastCategoryName).equals('Upside'))
      .asList();
    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OppInForecastTrueCategoryFunction_SL());
    }
  }

  /**
   */
  public static void deriveCommitForecastOnUpdate(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName, Opportunity.ForecastCategoryName },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.ForecastCategoryName).equals('Commit'))
      .asList();
    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OppInForecastTrueCategoryFunction_SL());
    }
  }

  /**
   */
  public static void deriveWonForecastOnUpdate(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.StageName },
      opps,
      existingOpps
    );
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(
        Match.field(Opportunity.StageName)
          .equals('Closed Won Booked')
          .also(Opportunity.In_Forecast__c)
          .hasValue()
          .also(Opportunity.In_Forecast__c)
          .equals(false)
      )
      .asList();
    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OppInForecastTrueCategoryFunction_SL());
    }
  }

  /**
   */
  public static void deriveCommitForecastOnInsert(List<Opportunity> opps) {
    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(Match.field(Opportunity.ForecastCategoryName).equals('Commit'))
      .asList();
    if (!changedOpps.isEmpty()) {
      Collection.of(changedOpps).mapAll(new OppInForecastTrueCategoryFunction_SL());
    }
  }
}