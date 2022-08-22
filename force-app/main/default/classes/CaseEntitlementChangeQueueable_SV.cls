public without sharing class CaseEntitlementChangeQueueable_SV extends AbstractQueueable {
  private final List<Case> cases;
  private static Boolean isAlreadyRun = false;

  public CaseEntitlementChangeQueueable_SV(List<Case> cases) {
    super('CaseEntitlementChangeQueueable_SV');
    this.cases = cases;
    //to allow for logging against record. only used in non-bulk contexts
    if (cases != null && cases.size() == 1) {
      this.setPrimaryRecordId(cases.get(0).Id);
    }
  }

  public override void work() {
    this.updateTargetDate(cases);
  }

  private void updateTargetDate(List<Case> cases) {
    Map<Id, CaseMilestone> caseMilestoneMap = new Map<Id, CaseMilestone>();
    for (CaseMilestone milestone : [
      SELECT Id, CaseId, TargetDate
      FROM CaseMilestone
      WHERE CaseId IN :cases AND IsCompleted = FALSE
      ORDER BY TargetDate DESC
    ]) {
      caseMilestoneMap.put(milestone.CaseId, milestone);
    }
    List<Case> casesToUpdate = new List<Case>();
    for (Case caseRecord : cases) {
      Case caseToUpdate = new Case(Id = caseRecord.Id, Milestone_Completed__c = true, Milestone_Target_Date__c = null);
      if (caseMilestoneMap.containsKey(caseRecord.Id)) {
        caseToUpdate.Milestone_Completed__c = false;
        caseToUpdate.Milestone_Target_Date__c = caseMilestoneMap.get(caseRecord.Id).TargetDate;
      }
      casesToUpdate.add(caseToUpdate);
    }
    fflib_SObjectDomain.getTriggerEvent(Cases_SV.class).disableAll();
    update casesToUpdate;
    fflib_SObjectDomain.getTriggerEvent(Cases_SV.class).enableAll();
  }

  public static void setTargetDate(List<Case> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Case.EntitlementId },
      records,
      existingRecords
    );
    List<Case> eligibleCases = (List<Case>) Collection.of(records)
      .filter(hasChanged)
      .filter(
        Match.field(Case.RecordTypeId)
          .isIn(
            new Set<String>{
              CaseMetadata_SV.IncidentRecordType,
              CaseMetadata_SV.CloudElementsRecordType,
              CaseMetadata_SV.ServiceRequestRecordType,
              CaseMetadata_SV.EngagementRequestRecordType,
              CaseMetadata_SV.JapanEngagementRequestRecordType,
              CaseMetadata_SV.SalesOperationRecordType,
              CaseMetadata_SV.AcademyRecordType,
              CaseMetadata_SV.JapanAcademyRecordType,
              CaseMetadata_SV.JapanLicensingRecordType,
              CaseMetadata_SV.JapanIncidentRecordType
            }
          )
      )
      .filter(Match.field(Case.Status).notEquals('Closed'))
      .filter(Match.field(Case.Status).notEquals('Merged Closed'))
      .asList();
    if (!eligibleCases.isEmpty()) {
      if (!isAlreadyRun) {
        isAlreadyRun = true;
        AbstractQueueable.enqueue(new CaseEntitlementChangeQueueable_SV(eligibleCases));
      }
    }
  }
}