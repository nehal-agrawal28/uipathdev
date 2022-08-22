public without sharing class PIApprovalMatrixFunction_ET implements SObjectToSObjectFunction {
  private Map<String, Id> appovers;
  private Map<Id, Opportunity> opportunities;
  private Map<Id, Account> partners;
  private Map<Id, ObjectTerritory2Association> mapOfAccountIdToValidterritory;

  public PIApprovalMatrixFunction_ET(List<Partner_Involvement__c> records) {
    List<Id> opportunityIds = Collection.of(records).pluckIds(Partner_Involvement__c.PartnerOpp_Name__c);
    List<Id> partnerIds = Collection.of(records).pluckIds(Partner_Involvement__c.Partner_Account_Name__c);

    this.opportunities = new Map<Id, Opportunity>(
      [
        SELECT Id, Account.Area__c, AccountId, Account.Geo__c, Account.Region__c, Territory_Name__c
        FROM Opportunity
        WHERE Id IN :opportunityIds
      ]
    );

    Set<Id> relatedCustomerIds = new Set<Id>();
    for (Opportunity opportunity : opportunities.values()) {
      relatedCustomerIds.add(opportunity.AccountId);
    }

    Type accTerritoryTypeInstance = Type.forName('AccountsService_ET');
    IAccountTerritory accountTerritory = (IAccountTerritory) accTerritoryTypeInstance.newInstance();
    mapOfAccountIdToValidterritory = accountTerritory.getValidAccountTerritory(relatedCustomerIds);

    this.partners = new Map<Id, Account>(
      [
        SELECT Id, Business_Partner_Type__c, Regional_Business_Partner_Type__c
        FROM Account
        WHERE Id IN :partnerIds AND RecordTypeId != :AccountMetadata.technologyAllianceRecordType
      ]
    );

    List<String> relatedOppsGeos = new List<String>();
    for (Partner_Involvement__c influencer : records) {
      //relatedOppsGeos.add(opportunities.get(influencer.PartnerOpp_Name__c).Account.Geo__c);
      Id accountId = opportunities.get(influencer.PartnerOpp_Name__c).AccountId;
      if (accountId != null && mapOfAccountIdToValidterritory.containsKey(accountId)) {
        relatedOppsGeos.add(mapOfAccountIdToValidterritory.get(accountId).Territory2.Ultimate_Geo__c);
      }
    }

    List<Quote_Approval_Matrix__c> matrixList = [
      SELECT Id, Approver__c, X2nd_Approver_GSI__c, X2nd_Approver_VAR__c, Geo__c, Region__c, Territory__c
      FROM Quote_Approval_Matrix__c
      WHERE Geo__c IN :relatedOppsGeos AND Type__c = 'Influence'
    ];

    this.appovers = new Map<String, Id>();
    for (Quote_Approval_Matrix__c matrix : matrixList) {
      appovers.put(matrix.Geo__c + '_' + matrix.Territory__c, matrix.Approver__c);
      appovers.put(matrix.Geo__c + '_' + matrix.Territory__c + '_GSI', matrix.X2nd_Approver_GSI__c);
      appovers.put(matrix.Geo__c + '_' + matrix.Territory__c + '_VAR', matrix.X2nd_Approver_VAR__c);
    }
  }

  public SObject apply(Partner_Involvement__c record) {
    if (!partners.containsKey(record.Partner_Account_Name__c)) {
      return record;
    }

    Id accountId = opportunities.get(record.PartnerOpp_Name__c).AccountId;
    if (accountId != null && mapOfAccountIdToValidterritory.containsKey(accountId)) {
      Territory2 territory = mapOfAccountIdToValidterritory.get(accountId).Territory2;

      /*String accountArea = opportunities.get(record.PartnerOpp_Name__c).Account.Area__c;
		String accountGeo = opportunities.get(record.PartnerOpp_Name__c).Account.Geo__c;
		String accountRegion = opportunities.get(record.PartnerOpp_Name__c).Account.Region__c;*/

      // Now Geo details will come from territory
      String accountArea = territory.Area__c;
      String accountGeo = territory.Ultimate_Geo__c;
      String accountRegion = territory.Region__c;

      record.Partner_Account_Geo_Text__c = accountGeo;
      record.Partner_Account_Area__c = accountArea;

      String optyTerritory = opportunities.get(record.PartnerOpp_Name__c).Territory_Name__c;
      String businessPartnerType = partners.get(record.Partner_Account_Name__c).Business_Partner_Type__c;
      String regionalPartnerType = partners.get(record.Partner_Account_Name__c).Regional_Business_Partner_Type__c;

      String firstApproverKey = accountGeo + '_' + optyTerritory;
      String secondApproverKey = accountGeo + '_' + optyTerritory + '_' + businessPartnerType;

      if (accountGeo == 'EMEA' && regionalPartnerType == 'RSI') {
        secondApproverKey = 'EMEA_' + optyTerritory + ' _GSI';
      }

      record.X1st_Approver__c = appovers.get(firstApproverKey);
      record.X2nd_Approver__c = appovers.get(secondApproverKey);
    }

    return record;
  }

  public SObject apply(SObject record) {
    return apply((Partner_Involvement__c) record);
  }

  public static void deriveApprovers(List<Partner_Involvement__c> records) {
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records)
      .filter(
        Match.field(Partner_Involvement__c.Partner_Sales_Role__c)
          .equals(PartnerInvolvementMetadata_SL.INFLUENCE_PARTNER_ROLE)
          .also(Partner_Involvement__c.Partner_Record_Type__c)
          .notEquals('Technology Alliance')
      )
      .asList();

    if (!eligibleRecords.isEmpty()) {
      Collection.of(eligibleRecords).mapAll(new PIApprovalMatrixFunction_ET(eligibleRecords));
    }
  }

  public static void deriveApprovers(List<Partner_Involvement__c> records, Map<Id, SObject> existingRecords) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Partner_Involvement__c.Partner_Sales_Role__c },
      records,
      existingRecords
    );
    List<Partner_Involvement__c> eligibleRecords = Collection.of(records).filter(hasChanged).asList();

    if (!eligibleRecords.isEmpty()) {
      deriveApprovers(eligibleRecords);
    }
  }
}