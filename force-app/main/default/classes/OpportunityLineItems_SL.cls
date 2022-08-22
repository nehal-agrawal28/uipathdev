/**
 * Responsibility: OpportunityLineItem Domain Class
 * Mostly just delegates work to Mapped Functions or to Async Queueables
 */
public with sharing class OpportunityLineItems_SL extends fflib_SObjectDomain implements IOpportunityLineItems_SL {
  public static IOpportunityLineItems_SL newInstance(List<OpportunityLineItem> recordList) {
    return (IOpportunityLineItems_SL) Application.Domain.newInstance(recordList);
  }

  public static IOpportunityLineItems_SL newInstance(Set<Id> recordIdSet) {
    return (IOpportunityLineItems_SL) Application.Domain.newInstance(recordIdSet);
  }

  public OpportunityLineItems_SL(List<OpportunityLineItem> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onBeforeInsert() {
    OpportunityLineItemFunction_SL.setDefaultValues(records);
  }

  public override void onBeforeUpdate(Map<Id, SObject> existingRecords) {
    OpportunityItemDateFunction_SL.setServiceDate(records, existingRecords);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new OpportunityLineItems_SL(sObjectList);
    }
  }
}