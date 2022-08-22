public with sharing class CaseValidateAutoReplyFunction_SV implements SObjectToSObjectFunction {
  public SObject apply(Case record) {
    if (String.isBlank(record.Subject)) {
      return record;
    }

    String subject = record.Subject.toLowerCase().trim();

    Set<String> wordsInSubject = new Set<String>(subject.split('\\s'));

    if (wordsInSubject.contains('pto')) {
      record.addError(CaseMetadata_SV.AUTOMATIC_REPLY_MESSAGE);
      return record;
    }

    for (String automaticEmail : CaseMetadata_SV.RestrictedSubjects) {
      if (record.Subject.containsIgnoreCase(automaticEmail)) {
        record.addError(CaseMetadata_SV.AUTOMATIC_REPLY_MESSAGE);
        break;
      }
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Case) record);
  }

  public static void checkSubject(List<SObject> records) {
    Collection.of(records).mapSome(Match.field(Case.Subject).hasValue(), new CaseValidateAutoReplyFunction_SV());
  }
}