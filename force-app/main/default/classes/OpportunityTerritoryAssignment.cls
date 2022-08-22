/**
 * @AUTHOR: UIPath
 * @DATE: 07/09/2021
 * @DESCRIPTION:  Apex version of the default logic.
 *  Case 1: If opportunity deal type is BPO and Managed Services
 *            then set territory2Id = creator's territory2Id
 *  Case 2: if opportunity deal type is other than BPO and Managed Services
 *            then set territory2Id = account's territory
 */
global with sharing class OpportunityTerritoryAssignment implements TerritoryMgmt.OpportunityTerritory2AssignmentFilter {
  /**
   * No-arg constructor.
   */
  global OpportunityTerritoryAssignment() {
  }

  /**
   * Get mapping of opportunity to territory2Id. The incoming list of opportunityIds contains only those with IsExcludedFromTerritory2Filter=false.
   * If territory2Id = null in result map, clear the opportunity.territory2Id if set.
   * If opportunity is not present in result map, its territory2Id remains intact.
   */
  global Map<Id, Id> getOpportunityTerritory2Assignments(List<Id> opportunityIds) {
    Opportunities_ET.isTerritoryUpdatedBySystem = true;
    OpportunitiesService_ET oppService = (OpportunitiesService_ET) Application_ET.Service.newInstance(
      OpportunitiesService_ET.class
    );
    return oppService.assignTerritoryToOpp(opportunityIds, false);
  }
}