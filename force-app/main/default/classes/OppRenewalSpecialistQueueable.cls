/**
 * Created by Mirela Chituc on 2/10/2021.
 * Add Opportunity.Renewal_Specialist__c in OTM with 'Edit' access and in ATM with 'Read' access on the opps
 */

public without sharing class OppRenewalSpecialistQueueable extends AbstractQueueable {
  public final List<SObject> oppList;
  public final Map<Id, SObject> oppOldMap;

  public OppRenewalSpecialistQueueable(List<SObject> oppList, Map<Id, SObject> oppOldMap) {
    super('OppRenewalSpecialistQueueable');
    this.oppList = oppList;
    this.oppOldMap = oppOldMap;
    //to allow for logging against record. only used in non-bulk contexts
    if (oppList.size() == 1) {
      this.setPrimaryRecordId(oppList.get(0).Id);
    }
  }

  public override void work() {
    if (this.oppOldMap == null)
      this.handleRenewalSpecialis(this.oppList, null);
    else
      this.handleRenewalSpecialis(this.oppList, this.oppOldMap);
  }

 /* public static void createRS(List<Opportunity> opps) {
    if (!opps.isEmpty()) {
      AbstractQueueable.enqueue(new OppRenewalSpecialistQueueable(opps, null));
    }
  }

  public static void updateRS(List<Opportunity> opps, Map<Id, SObject> existingOpps) {
    SObjectPredicate hasChanged = new HasRecordChanged(
      new Set<SObjectField>{ Opportunity.Renewal_Specialist__c },
      opps,
      existingOpps
    );

    List<Opportunity> eligibleOpps = (List<Opportunity>) Collection.of(opps).filter(hasChanged).asList();

    if (!eligibleOpps.isEmpty()) {
      AbstractQueueable.enqueue(new OppRenewalSpecialistQueueable(eligibleOpps, existingOpps));
    }
  }*/

  private void handleRenewalSpecialis(List<Opportunity> opps, Map<Id, sObject> oldMap) {
    Map<Id, Id> OTMtoInsert = new Map<Id, Id>();
    Map<Id, Id> ATMtoInsert = new Map<Id, Id>();
    Map<Id, String> OTMtoDelete = new Map<Id, String>();
    Map<Id, String> ATMtoDelete = new Map<Id, String>();
    if (oldMap == null) {
      for (Opportunity opp : opps) {
        if (opp.Renewal_Specialist__c != null) {
          OTMtoInsert.put(opp.Id, opp.Renewal_Specialist__c);
          ATMtoInsert.put(opp.AccountId, opp.Renewal_Specialist__c);
        }
      }
    } else {
      for (Opportunity opp : opps) {
        Opportunity oldOpp = (Opportunity) oldMap.get(opp.Id);
        if (opp.Renewal_Specialist__c != oldOpp.Renewal_Specialist__c) {
          if (opp.Renewal_Specialist__c != null) {
            OTMtoInsert.put(opp.Id, opp.Renewal_Specialist__c);
            ATMtoInsert.put(opp.AccountId, opp.Renewal_Specialist__c);
          }
          OTMtoDelete.put(opp.Id, String.valueOf(opp.Id) + '-' + String.valueOf(oldOpp.Renewal_Specialist__c));
          ATMtoDelete.put(
            opp.AccountId,
            String.valueOf(opp.AccountId) +
            '-' +
            String.valueOf(oldOpp.Renewal_Specialist__c)
          );
        }
      }
    }
    if (OTMtoDelete.size() > 0)
      DeleteOTMRenewalSpecialist(OTMtoDelete);
    if (ATMtoDelete.size() > 0)
      DeleteATMRenewalSpecialist(ATMtoDelete);
    if (OTMtoInsert.size() > 0)
      CreateOTMRenewalInsert(OTMtoInsert, ATMtoInsert);
  }

  private void DeleteOTMRenewalSpecialist(Map<Id, String> recordsToDelete) {
    List<OpportunityTeamMember> allRenewalSpecialists = [
      SELECT Id, OpportunityId, UserId, TeamMemberRole
      FROM OpportunityTeamMember
      WHERE OpportunityId IN :recordsToDelete.keySet() AND TeamMemberRole = 'Renewal Specialist'
    ];

    List<OpportunityTeamMember> RStoDEL = new List<OpportunityTeamMember>();
    for (OpportunityTeamMember otm : allRenewalSpecialists) {
      String oppIdUser = String.valueOf(otm.OpportunityId) + '-' + String.valueOf(otm.UserId);
      if (recordsToDelete.containsKey(otm.OpportunityId) && oppIdUser == recordsToDelete.get(otm.OpportunityId))
        RStoDEL.add(otm);
    }

    if (RStoDEL.size() > 0)
      delete RStoDEL;
  }

  private void DeleteATMRenewalSpecialist(Map<Id, String> recordsToDelete) {
    List<AccountTeamMember> allRenewalSpecialists = [
      SELECT Id, AccountId, UserId, TeamMemberRole
      FROM AccountTeamMember
      WHERE AccountId IN :recordsToDelete.keySet() AND TeamMemberRole = 'Renewal Specialist'
    ];

    List<AccountTeamMember> RStoDEL = new List<AccountTeamMember>();
    for (AccountTeamMember atm : allRenewalSpecialists) {
      String oppIdUser = String.valueOf(atm.AccountId) + '-' + String.valueOf(atm.UserId);
      if (recordsToDelete.containsKey(atm.AccountId) && oppIdUser == recordsToDelete.get(atm.AccountId))
        RStoDEL.add(atm);
    }

    if (RStoDEL.size() > 0)
      delete RStoDEL;
  }

  private void CreateOTMRenewalInsert(Map<Id, Id> recordsToInsert, Map<Id, Id> accRecordsToInsert) {
    List<OpportunityTeamMember> OTMtoInsert = new List<OpportunityTeamMember>();
    for (Id ikey : recordsToInsert.keySet()) {
      OpportunityTeamMember newOTM = new OpportunityTeamMember();
      newOTM.OpportunityId = ikey;
      newOTM.UserId = recordsToInsert.get(ikey);
      newOTM.TeamMemberRole = 'Renewal Specialist';
      newOTM.OpportunityAccessLevel = 'Edit';
      OTMtoInsert.add(newOTM);
    }

    List<AccountTeamMember> ATMtoInsert = new List<AccountTeamMember>();
    for (Id ikey : accRecordsToInsert.keySet()) {
      AccountTeamMember newATM = new AccountTeamMember();
      newATM.AccountId = ikey;
      newATM.AccountAccessLevel = 'Read';
      newATM.UserId = accRecordsToInsert.get(ikey);
      newATM.TeamMemberRole = 'Renewal Specialist';
      newATM.OpportunityAccessLevel = 'Edit';

      ATMtoInsert.add(newATM);
    }

    if (OTMtoInsert.size() > 0)
      insert OTMtoInsert;
    if (ATMtoInsert.size() > 0)
      insert ATMtoInsert;
  }
}