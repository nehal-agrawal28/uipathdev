public with sharing class OppRipReplaceNamingQueueable_SL extends AbstractQueueable {
  @TestVisible
  private OpportunitiesSelector_SL oppSelector {
    get {
      if (oppSelector == null) {
        oppSelector = (OpportunitiesSelector_SL) Application_SL.Selector.newInstance(Opportunity.SObjectType);
      }
      return oppSelector;
    }
    set;
  }
  private static final Set<Id> processedRecords = new Set<Id>();
  private final Set<Id> oppIds;
  private fflib_ISObjectUnitOfWork uow {
    get {
      if (uow == null) {
        uow = Application_SL.UnitOfWork.newInstance();
      }
      return uow;
    }
    set;
  }

  public OppRipReplaceNamingQueueable_SL(Set<Id> recordIds) {
    super('OppRipReplaceNamingQueueable_SL');
    this.oppIds = recordIds;

    //to allow for logging against record. only used in non-bulk contexts
    if (oppIds != null && oppIds.size() == 1) {
      this.setPrimaryRecordId(new List<Id>(oppIds).get(0));
      Logger.saveLog();
    }
  }

  public override void work() {
    this.setRipReplaceNamePrefix(oppIds);
  }

  public void setRipReplaceNamePrefix(Set<Id> oppIds) {
    List<Opportunity> oppsToUpdate = new List<Opportunity>();
    //selector to requery records to include SBQQ__PrimaryQuote__r.Replacement_Transaction__c
    List<Opportunity> opps = oppSelector.getOppsWithPrimaryQuote(oppIds);
    for (Opportunity opp : opps) {
      if (opp != null && opp.SBQQ__PrimaryQuote__r != null && opp.SBQQ__PrimaryQuote__r.Replacement_Quote__c != null) {
        oppsToUpdate.add(
          new Opportunity(Id = opp.Id, Name = Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX + opp.Name)
        );
      }
    }
    uow.registerDirty(oppsToUpdate);
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    uow.commitWork();
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();
  }

  public static void setNamePrefixOnRipReplaceAmendments(List<Opportunity> Records, Map<Id, SObject> existingRecords) {
    Set<Id> eligibleRecordIds = determineRecordEligibility(Records, existingRecords);
    if (!eligibleRecordIds.isEmpty()) {
      OppRipReplaceNamingQueueable_SL namingQueueable = new OppRipReplaceNamingQueueable_SL(eligibleRecordIds);
      System.enqueueJob(namingQueueable);
      processedRecords.addAll(eligibleRecordIds);
    }
  }

  @TestVisible
  private static Set<Id> determineRecordEligibility(List<Opportunity> Records, Map<Id, SObject> existingRecords) {
    if (Records == null || existingRecords == null) {
      return new Set<Id>();
    }

    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Amount },
      Records,
      existingRecords
    );

    SObjectPredicate needsRrPrefix = new NeedsRrPrefix(Opportunity.getSObjectType(), Records);

    SObjectPredicate isStillNotProcessed = new IsRecordNotProcessedYet(processedRecords);

    SObjectPredicate fieldInitialised = new FieldInitialised(
      Opportunity.getSObjectType(),
      Opportunity.Amount,
      (List<SObject>) Records,
      existingRecords
    );

    Set<Id> eligibleRecordIds = new Set<Id>(
      Collection.of(records)
        .filter(hasChanged)
        .filter(isStillNotProcessed)
        .filter(needsRrPrefix)
        .filter(fieldInitialised)
        .filter(Match.field(Opportunity.Cancellation_Transaction__c).hasValue())
        .filter(Match.field(Opportunity.Cancellation_Transaction__c).equals(true))
        .pluckIds()
    );
    return eligibleRecordIds;
  }

  private class NeedsRrPrefix implements SObjectPredicate {
    Map<Id, SObject> needsRrPrefix = new Map<Id, SObject>();

    public NeedsRrPrefix(Schema.SObjectType sobjectType, List<SObject> records) {
      Schema.DescribeSObjectResult describeResult = sobjectType.getDescribe();
      Map<String, Object> describeResultFieldsMap = describeResult.fields.getMap();
      if (!describeResultFieldsMap.containsKey('Name')) {
        return;
      }
      for (SObject newRecord : Records) {
        Id recordId = (Id) newRecord.get('Id');
        if (newRecord.get('Name') == null) {
          continue;
        } else {
          String name = (String) newRecord.get('Name');
          if (!name.contains(Constants_SL.OPPORTUNITY_NAME_RIP_REPLACE_PREFIX)) {
            needsRrPrefix.put(newRecord.Id, newRecord);
          }
        }
      }
    }

    public Boolean apply(SObject record) {
      return needsRrPrefix.containsKey(record.Id);
    }
  }

  private class FieldInitialised implements SObjectPredicate {
    Map<Id, SObject> fieldInitialised = new Map<Id, SObject>();

    public FieldInitialised(
      Schema.SObjectType sobjectType,
      Schema.SObjectField fieldToken,
      List<SObject> records,
      Map<Id, SObject> existingRecords
    ) {
      Schema.DescribeSObjectResult describeResult = sobjectType.getDescribe();
      Map<String, Object> describeResultFieldsMap = describeResult.fields.getMap();
      if (!describeResultFieldsMap.containsKey(String.valueOf(fieldToken))) {
        return;
      }
      for (SObject newRecord : Records) {
        Id recordId = (Id) newRecord.get('Id');
        if (existingRecords == null || !existingRecords.containsKey(recordId)) {
          continue;
        }
        SObject oldRecord = existingRecords.get(recordId);
        if (
          String.isEmpty(String.valueOf(oldRecord.get(fieldToken))) &&
          !String.isEmpty(String.valueOf(newRecord.get(fieldToken)))
        ) {
          fieldInitialised.put(newRecord.Id, newRecord);
        }
      }
    }

    public Boolean apply(SObject record) {
      return fieldInitialised.containsKey(record.Id);
    }
  }
}