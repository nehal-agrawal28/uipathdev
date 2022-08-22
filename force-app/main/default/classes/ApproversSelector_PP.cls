public virtual inherited sharing class ApproversSelector_PP extends fflib_SObjectSelector implements IApproversSelector_PP {
  public static IApproversSelector_PP newInstance() {
    return (IApproversSelector_PP) Application_PP.Selector.newInstance(Schema.sbaa__Approver__c.SObjectType);
  }

  public static IApproversSelector_PP newWithoutSharingInstance() {
    return (IApproversSelector_PP) Application_PP.ElevatedSelector.newInstance(Schema.sbaa__Approver__c.SObjectType);
  }

  public static IApproversSelector_PP newInheritedSharingInstance() {
    return (IApproversSelector_PP) Application_PP.InheritedSharingSelector.newInstance(
      Schema.sbaa__Approver__c.SObjectType
    );
  }

  public ApproversSelector_PP() {
    super();
  }

  public ApproversSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      sbaa__Approver__c.Id,
      sbaa__Approver__c.sbaa__User__c,
      sbaa__Approver__c.sbaa__GroupId__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Schema.sbaa__Approver__c.SObjectType;
  }

  public virtual List<sbaa__Approver__c> selectById(Set<Id> idSet) {
    return (List<sbaa__Approver__c>) selectSObjectsById(idSet);
  }

  public with sharing class WithSharing extends ApproversSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithSharing() {
      super(true, true, true);
    }

    public override List<sbaa__Approver__c> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }
  }

  public without sharing class WithoutSharing extends ApproversSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithoutSharing() {
      super(true, false, false);
    }

    public override List<sbaa__Approver__c> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }
  }
}