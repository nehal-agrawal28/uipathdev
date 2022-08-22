/**
 * @AUTHOR: UIPath
 * @DATE: 07/12/2021
 * @DESCRIPTION: This is territory2 object domain class
 */
public with sharing class Territories_ET extends fflib_SObjectDomain {
  public Territories_ET(List<Territory2> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onAfterInsert() {
    List<Territory2> terrToProcess = new List<Territory2>();
    for (Territory2 terr : (List<territory2>) records) {
      if (
        (terr.Sales_Area__c == true &&
        terr.AVP_Id__c != null) ||
        (terr.Sales_Region__c == true &&
        terr.RVP_Id__c != null) ||
        (terr.Sales_Geo__c == true &&
        terr.GVP_Id__c != null)
      ) {
        terrToProcess.add(terr);
      }
    }
    TerritoriesService_ET terrService = (TerritoriesService_ET) Application_ET.Service.newInstance(
      TerritoriesService_ET.class
    );
    terrService.populateAVPRVP(terrToProcess);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    TerritoriesService_ET terrService = (TerritoriesService_ET) Application_ET.Service.newInstance(
      TerritoriesService_ET.class
    );
    terrService.setRecalculateCompensationFlag(getRecords(), (Map<Id, Territory2>) existingRecords);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    List<Territory2> changedRecords = getChangedRecords(
      new Set<Schema.SObjectField>{ Territory2.AVP_Id__c, Territory2.RVP_Id__c, Territory2.GVP_Id__c }
    );

    if (changedRecords.isEmpty())
      return;
    TerritoriesService_ET terrService = (TerritoriesService_ET) Application_ET.Service.newInstance(
      TerritoriesService_ET.class
    );
    terrService.populateAVPRVP(changedRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Territories_ET(sObjectList);
    }
  }
}