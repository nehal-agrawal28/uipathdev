public with sharing class Opportunities_MK extends fflib_SObjectDomain implements IOpportunities_MK {
  public static IOpportunities_MK newInstance(List<Opportunity> recordList) {
    return (Opportunities_MK) Application.Domain.newInstance(recordList);
  }

  public static IOpportunities_MK newInstance(Set<Id> recordIdSet) {
    return (IOpportunities_MK) Application.Domain.newInstance(recordIdSet);
  }

  public Opportunities_MK(List<Opportunity> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  /**
   * Validates opties that are updated
   * @param existingRecords updated Records
   */
  public override void onValidate(Map<Id, SObject> existingRecords) {
    OppStageValidationFunction.validateStage(Records, existingRecords, this);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    OpportunityFunnelQueueable.OpportunityFunnelOnUpdate(Records, existingRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Opportunities_MK(sObjectList);
    }
  }
}