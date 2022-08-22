public with sharing class OppContactRoleFunction_SL implements SObjectToSObjectFunction {
  Map<Id, List<SObject>> contactRolesByOpportunityId;
  public OppContactRoleFunction_SL(List<OpportunityContactRole> opportunityContactRoles) {
    this.contactRolesByOpportunityId = Collection.of(opportunityContactRoles)
      .groupByIds(OpportunityContactRole.OpportunityId);
  }

  private SObject apply(Opportunity record) {
    record.Total_Contact_Roles__c = (contactRolesByOpportunityId.containsKey(record.Id))
      ? contactRolesByOpportunityId.get(record.Id).size()
      : 0;
    return record;
  }

  public SObject apply(SObject record) {
    return apply((Opportunity) record);
  }

  public static void setTotalContactRoles(List<Opportunity> Records) {
    List<OpportunityContactRole> opportunityContactRoles = [
      SELECT Id, OpportunityId
      FROM OpportunityContactRole
      WHERE OpportunityId IN :Records
    ];

    if (!opportunityContactRoles.isEmpty()) {
      Collection.of(Records).mapAll(new OppContactRoleFunction_SL(opportunityContactRoles));
    }
  }
}