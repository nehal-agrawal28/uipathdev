public without sharing class PIPrimaryInfluenceFunction_SL implements SObjectToSObjectFunction {
  private List<Id> opportunityIds = new List<Id>();
  private Map<Id, Account> techAlliances = new Map<Id, Account>();

  public PIPrimaryInfluenceFunction_SL(List<Partner_Involvement__c> records) {
    List<Id> relatedOpportunityIds = Collection.of(records).pluckIds(Partner_Involvement__c.PartnerOpp_Name__c);
    List<Partner_Involvement__c> influencePartners = [
      SELECT Id, PartnerOpp_Name__c
      FROM Partner_Involvement__c
      WHERE
        PartnerOpp_Name__c IN :relatedOpportunityIds
        AND Id NOT IN :records
        AND Partner_Sales_Role__c = :PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE
        AND Primary_Influence__c = TRUE
    ];
    this.opportunityIds = Collection.of(influencePartners).pluckIds(Partner_Involvement__c.PartnerOpp_Name__c);

    List<Id> relatedAccountIds = Collection.of(records).pluckIds(Partner_Involvement__c.Partner_Account_Name__c);
    this.techAlliances = new Map<Id, Account>(
      [
        SELECT Id
        FROM Account
        WHERE Id IN :relatedAccountIds AND RecordTypeId = :AccountMetadata.technologyAllianceRecordType
      ]
    );
  }

  public SObject apply(Partner_Involvement__c record) {
    if (this.opportunityIds.contains(record.PartnerOpp_Name__c)) {
      if (record.Primary_Influence__c == true) {
        record.addError(PartnerInvolvementMetadata_SL.DUPLICATE_PRIMARY_INFLUENCE);
      }
    } else if (!techAlliances.containsKey(record.Partner_Account_Name__c) && record.Id == null) {
      this.opportunityIds.add(record.PartnerOpp_Name__c);
      record.Primary_Influence__c = true;
    }
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Partner_Involvement__c) record);
  }

  public static void preventDuplicatePrimary(List<Partner_Involvement__c> records) {
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Partner_Involvement__c.Partner_Sales_Role__c)
          .equals(PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE)
      )
      .asList();
    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new PIPrimaryInfluenceFunction_SL(eligibleRecords));
    }
  }

  public static void preventDuplicatePrimary(List<Partner_Involvement__c> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{
        Partner_Involvement__c.Partner_Sales_Role__c,
        Partner_Involvement__c.Primary_Influence__c
      },
      records,
      existingRecords
    );
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records).filter(hasChanged).asList();

    if (!eligibleRecords.isEmpty()) {
      preventDuplicatePrimary(eligibleRecords);
    }
  }
}