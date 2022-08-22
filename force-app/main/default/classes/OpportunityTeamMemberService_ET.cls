/**
 * @AUTHOR: UIPath
 * @DATE: 15/03/2022
 * @DESCRIPTION: This is OpportunityTeamMemberService_ET class
 * createOpportunitySplits method execute when new OpportunityTeamMember record created with Create_Split__c = true,
 * creates a new Opportunity_Split__c record and associate the new Opportunity_Split__c record to OpportunityTeamMember Record
 * updateOpportunitySplits method executes when existing OpportunityTeamMember record updates the TeamMemberRole
 * and update the Opportunity_Split__c.TeamMemberRole__c which is associated to OpportunityTeamMember record
 */
public without sharing class OpportunityTeamMemberService_ET {
  public Map<String, Decimal> mapOfRoleToPercentage = new Map<String, Decimal>();
  public OpportunityTeamMemberService_ET() {
    CompensationSelector_ET compSelector = (CompensationSelector_ET) Application_ET.Selector.newInstance(
      Default_Compensation__mdt.SObjectType
    );
    for (Default_Compensation__mdt metadata : compSelector.selectAll()) {
      if (metadata.Status__c == 'Active' && !mapOfRoleToPercentage.containsKey(metadata.Role_In_Territory__c)) {
        mapOfRoleToPercentage.put(metadata.Role_In_Territory__c, metadata.Default_Percentage__c);
      }
    }
  }

  private static Map<String, Opportunity_Split__c> getExistingSplitsMap(Set<Id> oppIds) {
    Map<String, Opportunity_Split__c> mapOfOppUserIdToSplit = new Map<String, Opportunity_Split__c>();
    OpportunitySplitSelector_ET splitSelector = (OpportunitySplitSelector_ET) Application_ET.Selector.newInstance(
      Opportunity_Split__c.SObjectType
    );
    for (Opportunity_Split__c split : splitSelector.selectByOppId(oppIds)) {
      if (!mapOfOppUserIdToSplit.containsKey(split.Opportunity__c + '-' + split.User__c)) {
        mapOfOppUserIdToSplit.put(split.Opportunity__c + '-' + split.User__c, split);
      }
    }
    return mapOfOppUserIdToSplit;
  }

  public void updateOpportunitySplits(
    List<OpportunityTeamMember> listOfOppTeamMembers,
    Map<Id, SObject> existingRecords
  ) {
    Integer count = 0;
    Set<Id> setOfOppIds = new Set<Id>();
    Map<String, Opportunity_Split__c> mapOfOppUserIdToSplit = new Map<String, Opportunity_Split__c>();
    Map<Id, OpportunityTeamMember> mapOfOppSplitIdToTeamMember = new Map<Id, OpportunityTeamMember>();
    Map<Integer, OpportunityTeamMember> mapOfIndexToOppTeamMember = new Map<Integer, OpportunityTeamMember>();
    List<Opportunity_Split__c> listOfOppSplitsToUpdate = new List<Opportunity_Split__c>();

    for (OpportunityTeamMember teamMember : listOfOppTeamMembers) {
      setOfOppIds.add(teamMember.OpportunityId);
    }

    mapOfOppUserIdToSplit = getExistingSplitsMap(setOfOppIds);

    for (OpportunityTeamMember teamMember : listOfOppTeamMembers) {
      if (mapOfOppUserIdToSplit.containsKey(teamMember.OpportunityId + '-' + teamMember.UserId)) {
        teamMember.Opportunity_Split__c = mapOfOppUserIdToSplit.get(teamMember.OpportunityId + '-' + teamMember.UserId)
          .Id;
      }
    }

    for (OpportunityTeamMember teamMember : listOfOppTeamMembers) {
      OpportunityTeamMember existingTeamMember = (OpportunityTeamMember) existingRecords.get(teamMember.Id);
      if (teamMember.TeamMemberRole != null && teamMember.TeamMemberRole != existingTeamMember.TeamMemberRole) {
        if (
          teamMember.Opportunity_Split__c != null &&
          !mapOfOppSplitIdToTeamMember.containsKey(teamMember.Opportunity_Split__c)
        ) {
          mapOfOppSplitIdToTeamMember.put(teamMember.Opportunity_Split__c, teamMember);
        }
      }
    }

    for (Id oppSplitId : mapOfOppSplitIdToTeamMember.KeySet()) {
      String role = mapOfOppSplitIdToTeamMember.get(oppSplitId).TeamMemberRole;
      listOfOppSplitsToUpdate.add(
        new Opportunity_Split__c(
          Id = oppSplitId,
          TeamMemberRole__c = role,
          Percentage__c = mapOfRoleToPercentage.containsKey(role) ? mapOfRoleToPercentage.get(role) : 0
        )
      );
      mapOfIndexToOppTeamMember.put(count, mapOfOppSplitIdToTeamMember.get(oppSplitId));
      count += 1;
    }
    count = 0;
    for (Database.SaveResult result : Database.update(listOfOppSplitsToUpdate, false)) {
      if (!result.isSuccess()) {
        for (Database.Error error : result.getErrors()) {
          if (mapOfIndexToOppTeamMember.containsKey(count)) {
            OpportunityTeamMember teamMember = mapOfIndexToOppTeamMember.get(count);
            teamMember.addError(error.getMessage());
          }
        }
      }
      count += 1;
    }
  }

  public void createOpportunitySplits(List<OpportunityTeamMember> listOfOppTeamMembers) {
    Integer count = 0;
    Set<Id> setOfOppIds = new Set<Id>();
    List<Opportunity_Split__c> listOfOppSplitsToInsert = new List<Opportunity_Split__c>();
    Map<String, Opportunity_Split__c> mapOfOppUserIdToSplit = new Map<String, Opportunity_Split__c>();
    Map<Integer, OpportunityTeamMember> mapOfIndexToOppTeamMember = new Map<Integer, OpportunityTeamMember>();

    for (OpportunityTeamMember teamMember : listOfOppTeamMembers) {
      setOfOppIds.add(teamMember.OpportunityId);
    }

    mapOfOppUserIdToSplit = getExistingSplitsMap(setOfOppIds);

    for (OpportunityTeamMember teamMember : listOfOppTeamMembers) {
      if (teamMember.Create_Split__c) {
        listOfOppSplitsToInsert.add(
          new Opportunity_Split__c(
            Opportunity__c = teamMember.OpportunityId,
            TeamMemberRole__c = teamMember.TeamMemberRole,
            User__c = teamMember.UserId,
            Percentage__c = mapOfRoleToPercentage.containsKey(teamMember.TeamMemberRole)
              ? mapOfRoleToPercentage.get(teamMember.TeamMemberRole)
              : 0
          )
        );
        mapOfIndexToOppTeamMember.put(count, teamMember);
        count += 1;
      }
    }
    count = 0;
    for (Database.SaveResult result : Database.insert(listOfOppSplitsToInsert, false)) {
      if (!result.isSuccess()) {
        for (Database.Error error : result.getErrors()) {
          if (mapOfIndexToOppTeamMember.containsKey(count)) {
            OpportunityTeamMember teamMember = mapOfIndexToOppTeamMember.get(count);
            if (error.getMessage() != 'User is already a part of existing opportunity splits, cannot add this user.') {
              teamMember.addError(error.getMessage());
            }
          }
        }
      }
      count += 1;
    }

    count = 0;
    for (OpportunityTeamMember teamMember : listOfOppTeamMembers) {
      if (
        !listOfOppSplitsToInsert.isEmpty() &&
        listOfOppSplitsToInsert[count] != null &&
        listOfOppSplitsToInsert[count].Id != null
      ) {
        teamMember.Opportunity_Split__c = listOfOppSplitsToInsert[count].Id;
      } else if (mapOfOppUserIdToSplit.containsKey(teamMember.OpportunityId + '-' + teamMember.UserId)) {
        teamMember.Opportunity_Split__c = mapOfOppUserIdToSplit.get(teamMember.OpportunityId + '-' + teamMember.UserId)
          .Id;
      }
      count += 1;
    }
  }
}