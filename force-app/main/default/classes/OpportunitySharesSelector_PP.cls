public without sharing class OpportunitySharesSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      OpportunityShare.Id,
      OpportunityShare.OpportunityId,
      OpportunityShare.UserOrGroupId,
      OpportunityShare.OpportunityAccessLevel,
      OpportunityShare.RowCause
    };
  }

  public Schema.SObjectType getSObjectType() {
    return OpportunityShare.sObjectType;
  }

  public List<OpportunityShare> selectApexSharingByOpportunityIdsAndUserOrGroupIdsAndOpportunityAccessLevels(
    Set<Id> opportunityIds,
    Set<Id> userOrGroupIds,
    Set<String> opportunityAccessLevels,
    Boolean withSharing
  ) {
    String condition =
      'OpportunityId IN :opportunityIds' +
      ' AND ' +
      'UserOrGroupId IN :userOrGroupIds' +
      ' AND ' +
      'OpportunityAccessLevel IN :opportunityAccessLevels' +
      ' AND ' +
      'RowCause = \'Manual\'';

    if (withSharing) {
      return (List<OpportunityShare>) Database.query(
        newQueryFactory(true, true, true).setCondition(condition).toSOQL()
      );
    } else {
      return (List<OpportunityShare>) Database.query(
        newQueryFactory(false, false, true).setCondition(condition).toSOQL()
      );
    }
  }
}