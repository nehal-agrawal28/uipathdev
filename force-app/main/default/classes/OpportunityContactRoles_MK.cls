public with sharing class OpportunityContactRoles_MK extends fflib_SObjectDomain implements IOpportunityContactRoles_MK {
  public static IOpportunityContactRoles_MK newInstance(List<OpportunityContactRole> recordList) {
    return (IOpportunityContactRoles_MK) Application.Domain.newInstance(recordList);
  }

  public static IOpportunityContactRoles_MK newInstance(Set<Id> recordIdSet) {
    return (IOpportunityContactRoles_MK) Application.Domain.newInstance(recordIdSet);
  }

  public OpportunityContactRoles_MK(List<OpportunityContactRole> sObjectList) {
    super(sObjectList);
    this.Configuration.disableTriggerCRUDSecurity();
  }

  public override void onAfterInsert() {
    OpportunityContactRolesFunnel_MK.createFunnel(Trigger.new);
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new OpportunityContactRoles_MK(sObjectList);
    }
  }
}