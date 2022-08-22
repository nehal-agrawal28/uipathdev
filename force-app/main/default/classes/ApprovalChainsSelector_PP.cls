public virtual inherited sharing class ApprovalChainsSelector_PP extends fflib_SObjectSelector implements IApprovalChainsSelector_PP {
  public static IApprovalChainsSelector_PP newInstance() {
    return (IApprovalChainsSelector_PP) Application_PP.Selector.newInstance(Schema.sbaa__ApprovalChain__c.SObjectType);
  }

  public static IApprovalChainsSelector_PP newWithoutSharingInstance() {
    return (IApprovalChainsSelector_PP) Application_PP.ElevatedSelector.newInstance(
      Schema.sbaa__ApprovalChain__c.SObjectType
    );
  }

  public static IApprovalChainsSelector_PP newInheritedSharingInstance() {
    return (IApprovalChainsSelector_PP) Application_PP.InheritedSharingSelector.newInstance(
      Schema.sbaa__ApprovalChain__c.SObjectType
    );
  }

  public ApprovalChainsSelector_PP() {
    super();
  }

  public ApprovalChainsSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ sbaa__ApprovalChain__c.Id, sbaa__ApprovalChain__c.Name };
  }

  public Schema.SObjectType getSObjectType() {
    return Schema.sbaa__ApprovalChain__c.SObjectType;
  }

  public virtual List<sbaa__ApprovalChain__c> selectById(Set<Id> idSet) {
    return (List<sbaa__ApprovalChain__c>) selectSObjectsById(idSet);
  }

  public virtual List<sbaa__ApprovalChain__c> selectAll() {
    return Database.query(newQueryFactory().toSOQL());
  }

  public with sharing class WithSharing extends ApprovalChainsSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithSharing() {
      super(true, true, true);
    }

    public override List<sbaa__ApprovalChain__c> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<sbaa__ApprovalChain__c> selectAll() {
      return super.selectAll();
    }
  }

  public without sharing class WithoutSharing extends ApprovalChainsSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithoutSharing() {
      super(true, false, false);
    }

    public override List<sbaa__ApprovalChain__c> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<sbaa__ApprovalChain__c> selectAll() {
      return super.selectAll();
    }
  }
}