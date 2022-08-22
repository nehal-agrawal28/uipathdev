public class DataTeam_AddOppOwnerTeamMemberQueueable implements Queueable {
  private Map<Id, Id> opps = new Map<Id, Id>();
  private Map<Id, Id> leads = new Map<Id, Id>();
  private Boolean leadUpdate;

  public DataTeam_AddOppOwnerTeamMemberQueueable(Map<Id, Id> opps, Map<Id, Id> leads, Boolean l) {
    this.opps = opps;
    this.leads = leads;
    this.leadUpdate = l;
  }
  public void execute(QueueableContext context) {
    List<OpportunityTeamMember> otmToInsert = new List<OpportunityTeamMember>();
    for (Opportunity opp : [SELECT Id, OwnerId FROM Opportunity WHERE Id IN :opps.keySet() LIMIT 6000]) {
      OpportunityTeamMember otm = new OpportunityTeamMember();
      otm.OpportunityId = opp.Id;
      otm.UserId = opps.get(opp.Id);
      otm.TeamMemberRole = 'Opportunity Owner';
      otm.Created_on_opportunity_insert__c = true;
      otmToInsert.add(otm);
    }
    if (otmToInsert.size() > 0) {
      insert otmToInsert;
    }
    if (!Test.isRunningTest()) {
      if (leadUpdate == true) {
        Id jobId = System.enqueueJob(new DataTeam_UpdateOwnerLeadQueueable(opps, leads));
      } else {
        Id jobId = System.enqueueJob(new DataTeam_ReturnResultsQueueable(null, opps, null));
      }
    }
  }
}