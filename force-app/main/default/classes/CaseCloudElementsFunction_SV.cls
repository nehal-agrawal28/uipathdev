public with sharing class CaseCloudElementsFunction_SV implements SObjectToSObjectFunction {
  public SObject apply(Case record) {
    if (record.Subject == null) {
      return record;
    }
    if (record.Subject.containsIgnoreCase('very high')) {
      record.Priority = CaseMetadata_SV.URGENT;
    } else if (record.Subject.containsIgnoreCase(CaseMetadata_SV.HIGH)) {
      record.Priority = CaseMetadata_SV.HIGH;
    } else if (record.Subject.containsIgnoreCase(CaseMetadata_SV.LOW)) {
      record.Priority = CaseMetadata_SV.LOW;
    } else {
      record.Priority = CaseMetadata_SV.MEDIOUM;
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void derivePriority(List<SObject> records) {
    Collection.of(records)
      .mapSome(
        Match.field(Case.RecordTypeId).equals(CaseMetadata_SV.CloudElementsRecordType),
        new CaseCloudElementsFunction_SV()
      );
  }
}