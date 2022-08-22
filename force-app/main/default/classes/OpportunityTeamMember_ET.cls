public without sharing class OpportunityTeamMember_ET extends fflib_SObjectDomain {
  public OpportunityTeamMember_ET(List<OpportunityTeamMember> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    OpportunityTeamMemberService_ET teamMemberService = (OpportunityTeamMemberService_ET) Application_ET.Service.newInstance(
      OpportunityTeamMemberService_ET.class
    );
    teamMemberService.createOpportunitySplits(records);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    List<OpportunityTeamMember> changedRecords = getChangedRecords(
      new Set<Schema.SObjectField>{ OpportunityTeamMember.TeamMemberRole }
    );
    if (changedRecords.isEmpty())
      return;

    OpportunityTeamMemberService_ET teamMemberService = (OpportunityTeamMemberService_ET) Application_ET.Service.newInstance(
      OpportunityTeamMemberService_ET.class
    );
    teamMemberService.updateOpportunitySplits(changedRecords, existingRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new OpportunityTeamMember_ET(sObjectList);
    }
  }
}