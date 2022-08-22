public virtual inherited sharing class DefaultApplicationManagersSelector_PP extends fflib_SObjectSelector implements IDefaultApplicationManagersSelector_PP {
  public static IDefaultApplicationManagersSelector_PP newInstance() {
    return (IDefaultApplicationManagersSelector_PP) Application_PP.Selector.newInstance(
      Schema.Default_Application_Manager_PP__mdt.SObjectType
    );
  }

  public static IDefaultApplicationManagersSelector_PP newWithoutSharingInstance() {
    return (IDefaultApplicationManagersSelector_PP) Application_PP.ElevatedSelector.newInstance(
      Schema.Default_Application_Manager_PP__mdt.SObjectType
    );
  }

  public static IDefaultApplicationManagersSelector_PP newInheritedSharingInstance() {
    return (IDefaultApplicationManagersSelector_PP) Application_PP.InheritedSharingSelector.newInstance(
      Schema.Default_Application_Manager_PP__mdt.SObjectType
    );
  }

  public DefaultApplicationManagersSelector_PP() {
    super();
  }

  public DefaultApplicationManagersSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{
      Default_Application_Manager_PP__mdt.Id,
      Default_Application_Manager_PP__mdt.Country__c,
      Default_Application_Manager_PP__mdt.Geo__c,
      Default_Application_Manager_PP__mdt.Manager__c
    };
  }

  public Schema.SObjectType getSObjectType() {
    return Schema.Default_Application_Manager_PP__mdt.SObjectType;
  }

  public virtual List<Default_Application_Manager_PP__mdt> selectById(Set<Id> idSet) {
    return (List<Default_Application_Manager_PP__mdt>) selectSObjectsById(idSet);
  }

  public virtual List<Default_Application_Manager_PP__mdt> selectAll() {
    return Database.query(newQueryFactory().toSOQL());
  }

  public with sharing class WithSharing extends DefaultApplicationManagersSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithSharing() {
      super(true, true, true);
    }

    public override List<Default_Application_Manager_PP__mdt> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<Default_Application_Manager_PP__mdt> selectAll() {
      return super.selectAll();
    }
  }

  public without sharing class WithoutSharing extends DefaultApplicationManagersSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithoutSharing() {
      super(true, false, false);
    }

    public override List<Default_Application_Manager_PP__mdt> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<Default_Application_Manager_PP__mdt> selectAll() {
      return super.selectAll();
    }
  }
}