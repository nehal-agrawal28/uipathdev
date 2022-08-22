public class Leads_PP extends fflib_SObjectDomain {
  public Leads_PP(List<Lead> records) {
    super(records, Schema.Lead.SObjectType);
    Configuration.disableTriggerCRUDSecurity();
  }

  public static Leads_PP newInstance(Set<Id> ids) {
    return (Leads_PP) Application_PP.Domain.newInstance(ids);
  }

  public static Leads_PP newInstance(List<Lead> records) {
    return (Leads_PP) Application_PP.Domain.newInstance(records, Schema.Lead.SObjectType);
  }

  public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
    onChangedOwner().updatePAFOwner();
  }

  public void updatePAFOwner() {
    if (System.isFuture() || System.isBatch())
      return;
    LeadsService_PP.updatePAFOwner(getLeadIds());
  }

  public Leads_PP onChangedOwner() {
    Set<Schema.SObjectField> changedFields = new Set<Schema.SObjectField>{ Lead.OwnerId };
    List<Lead> result = (List<Lead>) getChangedRecords(changedFields);
    return new Leads_PP(result);
  }

  public Leads_PP disableAutoReassignOwner() {
    List<Lead> disabledLeads = new List<Lead>();
    for (Lead record : (List<Lead>) getRecords()) {
      record.Disable_Owner_Change__c = true;
      disabledLeads.add(record);
    }
    return new Leads_PP(disabledLeads);
  }

  public Set<Id> getOwnerIds() {
    return Utilities_PP.pluckIdField(getRecords(), Lead.OwnerId);
  }

  public Set<Id> getLeadIds() {
    return Utilities_PP.pluckIdField(getRecords(), Lead.Id);
  }

  public Set<Id> getQueueOwnerIds() {
    Set<Id> leadOwners = new Set<Id>();
    for (Id ownerId : getOwnerIds()) {
      if (ownerId.getSobjectType() != Schema.User.SObjectType) {
        leadOwners.add(ownerId);
      }
    }
    return leadOwners;
  }

  public Set<Id> getUserOwnerIds() {
    Set<Id> leadOwners = new Set<Id>();
    for (Id ownerId : getOwnerIds()) {
      if (ownerId.getSobjectType() == Schema.User.SObjectType) {
        leadOwners.add(ownerId);
      }
    }
    return leadOwners;
  }

  public Set<Id> getAllUserOwnerIds() {
    Set<Id> leadOwners = new Set<Id>();
    leadOwners.addAll(getUserOwnerIds());
    GroupsService_PP gService = new GroupsService_PP();
    leadOwners.addAll(gService.getFirstLevelUserIds(getQueueOwnerIds()));
    return leadOwners;
  }

  public Map<Id, Id> getOwnerGroupIdByLeadId() {
    Map<Id, Id> queueIdsByLeadId = new Map<Id, Id>();
    for (Lead record : (List<Lead>) getRecords()) {
      if (String.valueOf(record.OwnerId).startsWith('005'))
        continue;
      queueIdsByLeadId.put(record.Id, record.OwnerId);
    }
    return queueIdsByLeadId;
  }

  public Map<Id, User> getOwnerUserByLeadId() {
    UsersSelector_PP userSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    Map<Id, Id> ownerIdsByLeadId = new Map<Id, Id>();

    for (Lead record : (List<Lead>) getRecords()) {
      if (String.valueOf(record.OwnerId).startsWith('005')) {
        ownerIdsByLeadId.put(record.Id, record.OwnerId);
      }
    }

    Map<Id, User> leadOwnersByUserId = new Map<Id, User>(
      userSelector.selectById(new Set<Id>(ownerIdsByLeadId.values()), false)
    );

    Map<Id, User> leadOwnersByLeadId = new Map<Id, User>();
    for (Id leadId : ownerIdsByLeadId.keySet()) {
      Id userId = ownerIdsByLeadId.get(leadId);
      leadOwnersByLeadId.put(leadId, leadOwnersByUserId.get(userId));
    }
    return leadOwnersByLeadId;
  }

  // Domain methods - START - Should be moved to the domain class once the new fflib packages are installed
  public Map<Id, String> getCountryById() {
    Map<Id, String> result = new Map<Id, String>();
    for (Lead record : getLeads()) {
      result.put(record.Id, record.Country);
    }
    return result;
  }

  public List<Lead> getLeads() {
    return (List<Lead>) getRecords();
  }
  // Domain methods - END -

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new Leads_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new Leads_PP(sObjectList);
    }
  }
}