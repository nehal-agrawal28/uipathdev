public with sharing class CaseResetFRFlag_SV implements SObjectToSObjectFunction {
  public CaseResetFRFlag_SV(List<Case> cases) {
  }

  public SObject apply(Case newCase) {
    if (newCase.isClone()) {
      newCase.FR_Voilated__c = false;
    }
    return newCase;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void resetSalesOpsFR(List<SObject> cases) {
    Collection.of(cases)
      .mapSome(
        Match.field(Case.RecordTypeId)
          .equals(CaseMetadata_SV.SalesOperationRecordType)
          .also(Case.FR_Voilated__c)
          .hasValue()
          .also(Case.FR_Voilated__c)
          .equals(true),
        new CaseResetFRFlag_SV(cases)
      );
  }
}