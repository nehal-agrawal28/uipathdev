public class CaseLegalReqNotificationReqFunction_SL implements SObjectToSObjectFunction {
  public CaseLegalReqNotificationReqFunction_SL(List<Case> cases) {
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public SObject apply(Case record) {
    system.debug('record.Standard_Template__c' + record.Standard_Template__c);
    if (record.Standard_Template__c == 'Yes')
      record.Notification_Requirement__c = 'No';

    return record;
  }

  public static void setNotificationReq(List<Case> cases) {
    Collection.of(cases)
      .filter(Match.field(Case.RecordTypeId).isIn(new Set<String>{ CaseMetadata_SL.LegalRequestRecordType }))
      .mapAll(new CaseLegalReqNotificationReqFunction_SL(cases));
  }

  public static void setNotificationReq(List<Case> cases, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Case.Standard_Template__c, Case.Notification_Requirement__c },
      cases,
      existingRecords
    );
    Collection.of(cases)
      .filter(hasChanged)
      .filter(Match.field(Case.RecordTypeId).isIn(new Set<String>{ CaseMetadata_SL.LegalRequestRecordType }))
      .mapAll(new CaseLegalReqNotificationReqFunction_SL(cases));
  }
}