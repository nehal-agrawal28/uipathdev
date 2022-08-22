public class DataTeam_DeleteTMOSQueueable implements Queueable {
  private Map<Id, Id> opps = new Map<Id, Id>();
  private Map<Id, Id> leads = new Map<Id, Id>();
  private Boolean updateLeads;
  private String contentCSV;
  
  public DataTeam_DeleteTMOSQueueable(Map<Id, Id> accounts, Map<Id, Id> opps, Map<Id, Id> leads, Boolean o, Boolean l) {
    this.opps = opps;
    this.leads = leads;
    this.updateLeads = l;
    this.contentCSV = 'OPPORTUNITY ID,SUCCESS/FAILURE,ERROR MESSAGE\r\n';
  }

  public void execute(QueueableContext context) {
    List<OpportunityTeamMember> otmToDel = [
      SELECT Id
      FROM OpportunityTeamMember
      WHERE OpportunityId IN :opps.keySet() AND TeamMemberRole = 'Opportunity Owner'
      LIMIT 5000
    ];
    if (otmToDel.size() > 0)
      delete otmToDel;

    List<Opportunity_Split__c> osToDel = [
      SELECT Id
      FROM Opportunity_Split__c
      WHERE Opportunity__c IN :opps.keySet() AND Role__c = 'Opportunity Owner'
      LIMIT 5000
    ];
    if (osToDel.size() > 0)
      delete osToDel;

    if (opps.size() > 0 && !Test.isRunningTest())
      System.enqueueJob(new DataTeam_UpdateOwnerOppQueueable(opps, leads, updateLeads));
  }
}