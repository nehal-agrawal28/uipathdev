public virtual inherited sharing class ApprovalRulesSelector_PP extends fflib_SObjectSelector implements IApprovalRulesSelector_PP {
  public static IApprovalRulesSelector_PP newInstance() {
    return (IApprovalRulesSelector_PP) Application_PP.Selector.newInstance(Schema.sbaa__ApprovalRule__c.SObjectType);
  }

  public static IApprovalRulesSelector_PP newWithoutSharingInstance() {
    return (IApprovalRulesSelector_PP) Application_PP.ElevatedSelector.newInstance(
      Schema.sbaa__ApprovalRule__c.SObjectType
    );
  }

  public static IApprovalRulesSelector_PP newInheritedSharingInstance() {
    return (IApprovalRulesSelector_PP) Application_PP.InheritedSharingSelector.newInstance(
      Schema.sbaa__ApprovalRule__c.SObjectType
    );
  }

  public ApprovalRulesSelector_PP() {
    super();
  }

  public ApprovalRulesSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      sbaa__ApprovalRule__c.Id,
      sbaa__ApprovalRule__c.sbaa__ApprovalChain__c,
      sbaa__ApprovalRule__c.sbaa__Approver__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Schema.sbaa__ApprovalRule__c.SObjectType;
  }

  public virtual List<sbaa__ApprovalRule__c> selectById(Set<Id> idSet) {
    return (List<sbaa__ApprovalRule__c>) selectSObjectsById(idSet);
  }

  public virtual List<sbaa__ApprovalRule__c> selectByChainId(Set<Id> chainIds) {
    return Database.query(newQueryFactory().setCondition('sbaa__ApprovalChain__c IN :chainIds').toSOQL());
  }

  public with sharing class WithSharing extends ApprovalRulesSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithSharing() {
      super(true, true, true);
    }

    public override List<sbaa__ApprovalRule__c> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<sbaa__ApprovalRule__c> selectByChainId(Set<Id> chainIds) {
      return super.selectByChainId(chainIds);
    }
  }

  public without sharing class WithoutSharing extends ApprovalRulesSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithoutSharing() {
      super(true, false, false);
    }

    public override List<sbaa__ApprovalRule__c> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<sbaa__ApprovalRule__c> selectByChainId(Set<Id> chainIds) {
      return super.selectByChainId(chainIds);
    }
  }
}