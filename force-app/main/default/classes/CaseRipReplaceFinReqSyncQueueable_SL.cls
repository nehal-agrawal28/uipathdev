/**
 * Class provides trigger handling and async processing for 'Financial Request' Cases in a Rip and Replace context
 * to sync specific fields between parent ('Replacement Transaction') cases and their related child ('Cancellation
 * Transaction') cases at specific points in the 'Financial Request' case process
 */
public with sharing class CaseRipReplaceFinReqSyncQueueable_SL extends AbstractQueueable {
  @TestVisible
  private CasesSelector_SL recordSelector {
    get {
      if (recordSelector == null) {
        recordSelector = (CasesSelector_SL) Application_SL.Selector.newInstance(Case.SObjectType);
      }
      return recordSelector;
    }
    set;
  }
  private static final Set<Id> PROCESSED_RECORDS = new Set<Id>();
  private static final Id CASE_FINANCE_REQUEST_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
    .get(Constants.CASE_RECORD_TYPE_2)
    .getRecordTypeId();
  private final Set<Id> recordIds;
  private fflib_ISObjectUnitOfWork uow {
    get {
      if (uow == null) {
        uow = Application_SL.UnitOfWork.newInstance();
      }
      return uow;
    }
    set;
  }

  public CaseRipReplaceFinReqSyncQueueable_SL(Set<Id> recordIds) {
    super('CaseRipReplaceFinReqSync_SL');
    this.recordIds = recordIds;

    //to allow for logging against record. only used in non-bulk contexts
    if (recordIds != null && recordIds.size() == 1) {
      this.setPrimaryRecordId(new List<Id>(recordIds).get(0));
      Logger.saveLog();
    }
  }

  public override void work() {
    //Delegate work
    System.debug(LoggingLevel.ERROR, '*** 1. recordIds: ' + recordIds);
    List<Case> modifiedRecords = updateEligibleCancellationTransactionCases(recordIds);
    System.debug(LoggingLevel.ERROR, '*** 6.modifiedRecords: ' + modifiedRecords);
    //DML
    uow.registerDirty(modifiedRecords);
    uow.commitWork();
  }

  /**
   * @description processes scope parent 'Replacement Transaction' cases in a R&R context,
   * updating their related child 'Cancellation Transaction' case records to sync certain
   * fields between parent and child
   * @param recordIds ids of eligible parent case records
   * @return prototype child case records to be updated
   */
  @testvisible
  private List<Case> updateEligibleCancellationTransactionCases(Set<Id> recordIds) {
    //re-query parent cases
    Map<Id, Case> parentIdToParent = getParentIdToParentMap(
      recordSelector.selectReplacementTransactionQuoteIdsByCaseId(recordIds, false)
    );
    System.debug(LoggingLevel.ERROR, '*** 2z.parentIdToParent: ' + parentIdToParent);

    //replacementQuoteIdToParentCase
    Map<Id, Case> replacementQuoteIdToParentCase = getReplacementQuoteIdToParentCaseId(parentIdToParent.values());
    System.debug(LoggingLevel.ERROR, '*** 3.replacementQuoteIdToParentCase: ' + replacementQuoteIdToParentCase);

    //query child cases
    List<Case> childCases = recordSelector.selectCancellationTransactionCasesByReplacementQuoteIds(
      replacementQuoteIdToParentCase.keySet(),
      false
    );
    System.debug(LoggingLevel.ERROR, '*** 4.childCases: ' + childCases);

    //create parent Id to list of child records map
    Map<Id, List<Case>> parentIdToChildCases = getParentIdToChildCases(replacementQuoteIdToParentCase, childCases);
    System.debug(LoggingLevel.ERROR, '*** 5.parentIdToChildCases: ' + parentIdToChildCases);

    //delegate work to manipulate child records
    List<Case> updatedChildCasePrototypes = updateCancellationTransactionCaseRecords(
      parentIdToChildCases,
      parentIdToParent
    );

    return updatedChildCasePrototypes;
  }

  /**
   * @description processes case records with required Opp-Quote relationship into a map
   * @param parentCases the parent cases to process
   * @return map of case id to case
   */
  @testVisible
  private static Map<Id, Case> getParentIdToParentMap(List<Case> parentCases) {
    if (parentCases == null || parentCases.isEmpty()) {
      return new Map<Id, Case>();
    }
    System.debug(LoggingLevel.ERROR, '*** 2a.getParentIdToParentMap.parentCases: ' + parentCases);

    Map<Id, Case> parentIdToParent = new Map<Id, Case>(
      (List<Case>) Collection.of(parentCases)
        .filter(Match.field(Case.Opportunity__c).hasValue().also('Opportunity__r.SBQQ__PrimaryQuote__c').hasValue())
        .asList()
    );
    System.debug(LoggingLevel.ERROR, '*** 2b.getParentIdToParentMap.parentIdToParent: ' + parentIdToParent);

    return parentIdToParent;
  }

  /**
   * @description processes parent cases to produce a map from the cases related replacement
   * quote to the parent case id
   * @param parentCases parent cases to process
   * @return map of quote id to case
   */
  @testVisible
  private static Map<Id, Case> getReplacementQuoteIdToParentCaseId(List<Case> parentCases) {
    if (parentCases == null || parentCases.isEmpty()) {
      return new Map<Id, Case>();
    }
    Map<Id, Case> replacementQuoteIdToParentCaseId = new Map<Id, Case>();
    List<Case> filteredCases = (List<Case>) Collection.of(parentCases)
      .filter(Match.field(Case.Opportunity__c).hasValue().also('Opportunity__r.SBQQ__PrimaryQuote__c').hasValue())
      .asList();
    for (Case c : filteredCases) {
      replacementQuoteIdToParentCaseId.put(c.Opportunity__r.SBQQ__PrimaryQuote__c, c);
    }

    return replacementQuoteIdToParentCaseId;
  }

  /**
   * @description produces a map to traverse from the parent case to the collection of child cases
   * @param replacementQuoteIdToParentCase traversal from replacement quote id to the parent case
   * @param childCases child case records with opp.quote.replacement quote reference
   * @return map traversal from a parent case id to a list of its related child cases
   */
  @testVisible
  private static Map<Id, List<Case>> getParentIdToChildCases(
    Map<Id, Case> replacementQuoteIdToParentCase,
    List<Case> childCases
  ) {
    if (
      replacementQuoteIdToParentCase == null ||
      replacementQuoteIdToParentCase.isEmpty() ||
      childCases == null ||
      childCases.isEmpty()
    ) {
      return new Map<Id, List<Case>>();
    }
    Map<Id, List<Case>> parentIdToChildCases = new Map<Id, List<Case>>();

    for (Case childCase : childCases) {
      if (
        childCase.Opportunity__c == null ||
        childCase.Opportunity__r.SBQQ__PrimaryQuote__c == null ||
        childCase.Opportunity__r.SBQQ__PrimaryQuote__r.Replacement_Quote__c == null ||
        !replacementQuoteIdToParentCase.containsKey(childCase.Opportunity__r.SBQQ__PrimaryQuote__r.Replacement_Quote__c)
      ) {
        continue;
      }
      Id repQuoteId = childCase.Opportunity__r.SBQQ__PrimaryQuote__r.Replacement_Quote__c;
      Id parentCaseId = replacementQuoteIdToParentCase.get(repQuoteId).Id;

      List<Case> parentsChildCases = parentIdToChildCases.containsKey(parentCaseId)
        ? parentIdToChildCases.get(parentCaseId)
        : new List<Case>();

      parentsChildCases.add(childCase);
      parentIdToChildCases.put(parentCaseId, parentsChildCases);
    }

    return parentIdToChildCases;
  }

  /**
   * @description creates case prototypes for updating relevant child case records
   * @param parentIdToChildCases traversal from parent case id to collected child cases
   * @param parentIdToParent traversal from parent case id to parent case
   * @return prototype case records to update
   */
  @testVisible
  private static List<Case> updateCancellationTransactionCaseRecords(
    Map<Id, List<Case>> parentIdToChildCases,
    Map<Id, Case> parentIdToParent
  ) {
    if (
      parentIdToChildCases == null ||
      parentIdToChildCases.isEmpty() ||
      parentIdToParent == null ||
      parentIdToParent.isEmpty()
    ) {
      return new List<Case>();
    }
    List<Case> prototypeRecords = new List<Case>();

    for (Id id : parentIdToChildCases.keySet()) {
      if (
        !parentIdToParent.containsKey(id) ||
        parentIdToChildCases.get(id) == null ||
        parentIdToChildCases.get(id).size() == 0
      ) {
        continue;
      }
      Case parentCase = parentIdToParent.get(id);
      if (
        parentCase.Status == null ||
        String.isBlank(parentCase.Status) ||
        parentCase.Deal_Hub_Owner__c == null ||
        String.isBlank(String.valueOf(parentCase.Deal_Hub_Owner__c))
      ) {
        continue;
      }
      List<Case> childCases = parentIdToChildCases.get(id);
      for (Case childCase : childCases) {
        prototypeRecords.add(
          new Case(Id = childCase.Id, Status = parentCase.Status, Deal_Hub_Owner__c = parentCase.Deal_Hub_Owner__c)
        );
      }
    }

    return prototypeRecords;
  }

  /**
   * @description after update handler entry, checks R&R sync feature enablement, delegates eligibility checks, enqueues
   * eligible records for async processing, records processed record ids
   * @param Records current state of records entering trigger handling
   * @param ExistingRecords previous state of records entering trigger handling
   */
  public static void syncCancellationTransactionCases(List<Case> Records, Map<Id, SObject> ExistingRecords) {
    if (!isSyncFeatureEnabled(Case.getSObjectType())) {
      return;
    }

    Set<Id> eligibleRecordIds = determineRecordEligibility(Records, existingRecords);
    if (!eligibleRecordIds.isEmpty()) {
      CaseRipReplaceFinReqSyncQueueable_SL queueable = new CaseRipReplaceFinReqSyncQueueable_SL(eligibleRecordIds);
      AbstractQueueable.enqueue(queueable);
      PROCESSED_RECORDS.addAll(eligibleRecordIds);
    }
  }

  /**
   * @description delegated record eligibility processing
   * @param Records current state of records entering trigger handling
   * @param ExistingRecords previous state of records entering trigger handling
   * @return set of records determined to be eligible for further processing
   */
  @TestVisible
  private static Set<Id> determineRecordEligibility(List<Case> Records, Map<Id, SObject> ExistingRecords) {
    if (Records == null || existingRecords == null || Records.isEmpty() || ExistingRecords.isEmpty()) {
      return new Set<Id>();
    }
    SObjectPredicate hasChanged = new HasRecordChanged(new Set<SObjectField>{ Case.Status }, Records, existingRecords);
    SObjectPredicate isStillNotProcessed = new IsRecordNotProcessedYet(PROCESSED_RECORDS);

    SObjectPredicate hasPriorStatusValue = new HasPriorFieldStringValue(
      Case.getSObjectType(),
      Case.Status,
      Constants_SL.CASE_STATUS_DEAL_HUB_REVIEW,
      Records,
      ExistingRecords
    );

    Set<Id> eligibleRecordIds = new Set<Id>(
      Collection.of(Records)
        .filter(hasChanged)
        .filter(isStillNotProcessed)
        .filter(hasPriorStatusValue)
        .filter(
          Match.field(Case.RecordTypeId)
            .hasValue()
            .also(Case.RecordTypeId)
            .equals(CASE_FINANCE_REQUEST_RT_ID)
            .also(Case.Replacement_Transaction__c)
            .hasValue()
            .also(Case.Replacement_Transaction__c)
            .equals(true)
        )
        .pluckIds()
    );
    return eligibleRecordIds;
  }

  /**
   * @description determines the sync feature enablement for a given sobject type via CMT feature toggles
   * @param sobjType the SObject type to determine sync feature enablement for
   * @return boolean of sync feature enablement for given sobject
   */
  @testVisible
  private static Boolean isSyncFeatureEnabled(Schema.SObjectType sobjType) {
    Boolean objectSyncEnabled = false;
    CPQRipReplaceSyncFeaturesSelector_SL cmtSelector = (CPQRipReplaceSyncFeaturesSelector_SL) Application_SL.Selector.newInstance(
      CPQ_RR_Sync_Feature__mdt.SObjectType
    );
    List<CPQ_RR_Sync_Feature__mdt> cmtRecords = cmtSelector.getAll();

    if (cmtRecords != null && cmtRecords.size() > 0 && sobjType != null) {
      Set<Id> filteredCmtId = new Set<Id>(
        Collection.of(cmtRecords)
          .filter(
            Match.field(CPQ_RR_Sync_Feature__mdt.Sync_Target_Object__c)
              .hasValue()
              .also(CPQ_RR_Sync_Feature__mdt.Sync_Target_Object__c)
              .equals(String.valueOf(sobjType))
              .also(CPQ_RR_Sync_Feature__mdt.Is_Active__c)
              .hasValue()
              .also(CPQ_RR_Sync_Feature__mdt.Is_Active__c)
              .equals(true)
          )
          .pluckIds()
      );
      if (!filteredCmtId.isEmpty()) {
        objectSyncEnabled = true;
      }
    }

    return objectSyncEnabled;
  }

  /**
   * @description for a given sobject type, field, and string value, determines for supplied records
   * whether the prior value of the field matches the supplied string value
   */
  @testVisible
  private class HasPriorFieldStringValue implements SObjectPredicate {
    Set<Id> hasPriorValue = new Set<Id>();

    public HasPriorFieldStringValue(
      Schema.SObjectType sobjectType,
      Schema.SObjectField field,
      String fieldPriorValue,
      List<SObject> records,
      Map<Id, SObject> existingRecords
    ) {
      Schema.DescribeSObjectResult describeResult = sobjectType.getDescribe();
      Map<String, Object> describeResultFieldsMap = describeResult.fields.getMap();
      if (!describeResultFieldsMap.containsKey(String.valueOf(field))) {
        return;
      }
      for (SObject currentRecord : records) {
        Id recordId = (Id) currentRecord.get('Id');
        if (
          currentRecord.get(String.valueOf(field)) == null ||
          !existingRecords.containsKey(recordId) ||
          existingRecords.get(recordId).get(String.valueOf(String.valueOf(field))) == null
        ) {
          continue;
        } else {
          String oldFieldValue = (String) existingRecords.get(recordId).get(String.valueOf(field));
          if (oldFieldValue == fieldPriorValue) {
            hasPriorValue.add(currentRecord.Id);
          }
        }
      }
    }

    public Boolean apply(SObject record) {
      return hasPriorValue.contains(record.Id);
    }
  }
}