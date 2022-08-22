public without sharing class QuoteMetadata_SL {
  //Status Names
  public static final String PENDING = 'Pending';
  public static final String IN_REVIEW = 'In Review';
  public static final String APPROVED = 'Approved';
  public static final String REJECTED = 'Rejected';
  public static final String RECALLED = 'Recalled';
  public static final String DRAFT = 'Draft';
  public static final String ACCEPTED = 'Accepted';

  //Record Type Developer Names
  private static final String CPQ_APPROVED = 'CPQ_Approved';
  private static final String CPQ_DEFAULT = 'CPQ_Default';

  private static Id getRecordTypeId(String developerName) {
    Id recordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByDeveloperName()
      .get(developerName)
      .getRecordTypeId();
    return recordTypeId;
  }

  public static Id CPQApprovedRecordType {
    get {
      if (CPQApprovedRecordType == null) {
        CPQApprovedRecordType = getRecordTypeId(CPQ_APPROVED);
      }
      return CPQApprovedRecordType;
    }
    set;
  }

  public static Id CPQDefaultRecordType {
    get {
      if (CPQDefaultRecordType == null) {
        CPQDefaultRecordType = getRecordTypeId(CPQ_DEFAULT);
      }
      return CPQDefaultRecordType;
    }
    set;
  }

  public static List<CPQ_Controls__mdt> QuoteTemplateMapping {
    get {
      if (QuoteTemplateMapping == null) {
        QuoteTemplateMapping = new List<CPQ_Controls__mdt>(
          [
            SELECT
              Id,
              JA_CPQ_Template__c,
              JA_CPQ_Email_Template__c,
              EN_CPQ_Template__c,
              EN_CPQ_Email_Template__c,
              EN_Disti_CPQ_Template__c,
              EN_CPQ_Template_SKU__c
            FROM CPQ_Controls__mdt
            LIMIT 1
          ]
        );
      }
      return QuoteTemplateMapping;
    }
    set;
  }
}