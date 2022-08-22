public with sharing class OppTypeOnUpdateQueueable_SL extends AbstractQueueable {
  private final List<SObject> opps;

  public OppTypeOnUpdateQueueable_SL(List<SObject> opps) {
    super('OppTypeOnUpdateQueueable_SL');
    this.opps = opps;
    //to allow for logging against record. only used in non-bulk contexts
    if (opps != null && opps.size() == 1) {
      this.setPrimaryRecordId(opps.get(0).Id);
    }
  }

  public override void work() {
    this.updateTypeOnOpties(this.opps);
  }

  private void updateTypeOnOpties(List<SObject> opps) {
    List<Opportunity> oppToUpdate = new List<Opportunity>();

    for (Opportunity opp : [
      SELECT Id, Account.won_opportunities__c, Replacement_Transaction__c
      FROM Opportunity
      WHERE Id IN :opps
    ]) {
      if (
        (opp.Account.won_opportunities__c != null && opp.Account.won_opportunities__c > 0) ||
        opp.Replacement_Transaction__c
      ) {
        opp.Type = 'Upsell';
        oppToUpdate.add(opp);
      }
    }
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update oppToUpdate;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();
  }

  /**
   * Set Opportunity Type on update
   */
  public static void setType(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    List<Opportunity> changedOpps = determineOppScope(opps, existingOpps);

    if (!changedOpps.isEmpty()) {
      AbstractQueueable.enqueue(new OppTypeOnUpdateQueueable_SL(changedOpps));
    }
  }

  /**
   * Set Opportunity Type on insert
   */
  public static void setType(List<Opportunity> opps) {
    List<Opportunity> scopeOpps = Collection.of(opps)
      .filter(Match.field(Opportunity.Type).notEquals('Renewal').also(Opportunity.Overwrite_Type__c).equals(false))
      .asList();

    if (!scopeOpps.isEmpty()) {
      AbstractQueueable.enqueue(new OppTypeOnUpdateQueueable_SL(scopeOpps));
    }
  }

  public class AccountIdChangedORReplacementTransactionSetORFieldsChangedAtCWP implements SObjectPredicate {
    Map<Id, SObject> changedRecords = new Map<Id, SObject>();

    public AccountIdChangedORReplacementTransactionSetORFieldsChangedAtCWP(
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
        //all accountId changes are in scope, except when already in CWB
        if (
          oldRecord.get(Opportunity.AccountId) != newRecord.get(Opportunity.AccountId) &&
          (newRecord.get(Opportunity.StageName) != OpportunityMetadata_SL.CLOSED_WON_BOOKED)
        ) {
          changedRecords.put(newRecord.Id, newRecord);
          continue;
        }
        //all Replacement_Transaction__c set to true are in scope, except when already in CWB
        if (
          (newRecord.get(Opportunity.Replacement_Transaction__c) != null &&
          oldRecord.get(Opportunity.Replacement_Transaction__c) != null) &&
          (!(Boolean) oldRecord.get(Opportunity.Replacement_Transaction__c) &&
          (Boolean) newRecord.get(Opportunity.Replacement_Transaction__c)) &&
          (newRecord.get(Opportunity.StageName) != OpportunityMetadata_SL.CLOSED_WON_BOOKED)
        ) {
          changedRecords.put(newRecord.Id, newRecord);
          continue;
        }
        //for all other tracked field changes  - opp.stage must be CWP to be in scope
        if (newRecord.get(Opportunity.StageName) != OpportunityMetadata_SL.CLOSED_WON_PENDING) {
          continue;
        }
        for (Schema.SObjectField fieldToken : fieldTokens) {
          if (oldRecord.get(fieldToken) != newRecord.get(fieldToken)) {
            changedRecords.put(newRecord.Id, newRecord);
            break;
          }
        }
      }
    }

    public Boolean apply(SObject record) {
      return changedRecords.containsKey(record.Id);
    }
  }

  @TestVisible
  private static List<Opportunity> determineOppScope(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new AccountIdChangedORReplacementTransactionSetORFieldsChangedAtCWP(
      new Set<SObjectField>{ Opportunity.StageName, Opportunity.Overwrite_Type__c, Opportunity.RecordTypeId },
      opps,
      existingOpps
    );

    List<Opportunity> changedOpps = Collection.of(opps)
      .filter(hasChanged)
      .filter(Match.field(Opportunity.Type).notEquals('Renewal').also(Opportunity.Overwrite_Type__c).equals(false))
      .asList();

    return changedOpps;
  }
}