public with sharing class Opportunities_ET extends fflib_SObjectDomain {
  public static boolean isTerritoryUpdatedBySystem = false;

  public Opportunities_ET(List<Opportunity> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    List<Opportunity> changedRecords = getChangedRecords(
      new Set<Schema.SObjectField>{ Opportunity.Territory2Id, Opportunity.StageName }
    );
    Set<Id> setOfTerritory2Ids = new Set<Id>();
    Map<Id, Territory2> mapOfTerritory2;
    if (changedRecords.isEmpty())
      return;

    OpportunitiesService_ET service = (OpportunitiesService_ET) Application_ET.Service.newInstance(
      OpportunitiesService_ET.class
    );
    service.beforeUpdateOpportunity(changedRecords, existingRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Opportunities_ET(sObjectList);
    }
  }
}