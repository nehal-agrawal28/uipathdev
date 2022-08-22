public without sharing class PIBusinessPartnerFieldsFunction_SL implements SObjectToSObjectFunction {
  Map<Id, Account> relatedPartnerAccounts = new Map<Id, Account>();

  public PIBusinessPartnerFieldsFunction_SL(List<Partner_Involvement__c> records) {
    List<Id> relatedPartnerAccountIds = Collection.of(records).pluckIds(Partner_Involvement__c.Partner_Account_Name__c);

    relatedPartnerAccounts = new Map<Id, Account>(
      [
        SELECT Id, Business_Partner_Status__c, Business_Partner_Level__c, Business_Partner_Type__c
        FROM Account
        WHERE Id IN :relatedPartnerAccountIds
      ]
    );
  }

  public SObject apply(Partner_Involvement__c record) {
    if (relatedPartnerAccounts.get(record.Partner_Account_Name__c).Business_Partner_Status__c != null) {
      record.Business_Partner_Status__c = relatedPartnerAccounts.get(record.Partner_Account_Name__c)
        .Business_Partner_Status__c;
    }
    if (relatedPartnerAccounts.get(record.Partner_Account_Name__c).Business_Partner_Type__c != null) {
      record.Business_Partner_Type__c = relatedPartnerAccounts.get(record.Partner_Account_Name__c)
        .Business_Partner_Type__c;
    }
    if (relatedPartnerAccounts.get(record.Partner_Account_Name__c).Business_Partner_Level__c != null) {
      record.Business_Partner_Level__c = relatedPartnerAccounts.get(record.Partner_Account_Name__c)
        .Business_Partner_Level__c;
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Partner_Involvement__c) record);
  }

  public static void deriveBusinessPartnerFields(List<Partner_Involvement__c> records) {
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Partner_Involvement__c.PartnerOpp_Name__c)
          .hasValue()
          .also(Partner_Involvement__c.Partner_Account_Name__c)
          .hasValue()
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new PIBusinessPartnerFieldsFunction_SL(eligibleRecords));
    }
  }

  public static void deriveBusinessPartnerFields(
    List<Partner_Involvement__c> records,
    Map<Id, SObject> existingRecords
  ) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{
        Partner_Involvement__c.PartnerOpp_Name__c,
        Partner_Involvement__c.Partner_Account_Name__c
      },
      records,
      existingRecords
    );
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records)
      .filter(hasChanged)
      .filter(
        Match.field(Partner_Involvement__c.PartnerOpp_Name__c)
          .hasValue()
          .also(Partner_Involvement__c.Partner_Account_Name__c)
          .hasValue()
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new PIBusinessPartnerFieldsFunction_SL(eligibleRecords));
    }
  }
}