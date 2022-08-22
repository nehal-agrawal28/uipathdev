trigger OpportunityTeamMemberAll on OpportunityTeamMember(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete
) {
TriggerInjector.handle(OpportunityTeamMember.SobjectType);
  /* if(Trigger.isAfter)
    {
        if(Trigger.isInsert){
            OppTeamMemberHandlerAll.CreateOpportunitySplits(Trigger.new);
        }
        if(Trigger.isUpdate){
            OppTeamMemberHandlerAll.UpdateOpportunitySplits(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isDelete){
            OppTeamMemberHandlerAll.RemoveOpportunitySplits(Trigger.old);
        }
    }*/
  if (Trigger.isBefore) {
    if (Trigger.isInsert) {
      OppTeamMemberHandlerAll.preventAddingTeamMember(Trigger.new, null);
      //OppTeamMemberHandlerAll.PreventAddingOppOwnerAndGAM(Trigger.new);
    }
    if (Trigger.isUpdate) {
      OppTeamMemberHandlerAll.preventAddingTeamMember(Trigger.new, Trigger.oldMap);
      //OppTeamMemberHandlerAll.PreventAddingOppOwnerAndGAM(Trigger.new);
    }
    if (Trigger.isDelete) {
      OppTeamMemberHandlerAll.preventDeletingOppOwnerAndGAM(Trigger.old);
      OppTeamMemberHandlerAll.preventDeletion(Trigger.old);
    }
  }
}