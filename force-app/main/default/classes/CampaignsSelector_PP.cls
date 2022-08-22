public virtual inherited sharing class CampaignsSelector_PP extends fflib_SObjectSelector implements ICampaignsSelector_PP {
  public static ICampaignsSelector_PP newInstance() {
    return (ICampaignsSelector_PP) Application_PP.Selector.newInstance(Schema.Campaign.SObjectType);
  }

  public static ICampaignsSelector_PP newWithoutSharingInstance() {
    return (ICampaignsSelector_PP) Application_PP.ElevatedSelector.newInstance(Schema.Campaign.SObjectType);
  }

  public CampaignsSelector_PP() {
    super();
  }

  public CampaignsSelector_PP(Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS) {
    super(includeFieldSetFields, enforceCRUD, enforceFLS);
  }

  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ Campaign.Id, Campaign.Name };
  }

  public Schema.SObjectType getSObjectType() {
    return Schema.Campaign.SObjectType;
  }

  public virtual List<Campaign> selectById(Set<Id> idSet) {
    return (List<Campaign>) selectSObjectsById(idSet);
  }

  public virtual List<Campaign> selectByName(String campaignName) {
    return selectByName(new Set<String>{ campaignName });
  }

  public virtual List<Campaign> selectByName(Set<String> campaignNames) {
    return (List<Campaign>) Database.query(newQueryFactory().setCondition('Name IN :campaignNames').toSOQL());
  }

  public with sharing class WithSharing extends CampaignsSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithSharing() {
      super(true, true, true);
    }

    public override List<Campaign> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<Campaign> selectByName(String campaignName) {
      return super.selectByName(campaignName);
    }

    public override List<Campaign> selectByName(Set<String> campaignNames) {
      return super.selectByName(campaignNames);
    }
  }

  public without sharing class WithoutSharing extends CampaignsSelector_PP {
    // Constructor that will enforce CRUD and FLS
    public WithoutSharing() {
      super(true, false, false);
    }

    public override List<Campaign> selectById(Set<Id> idSet) {
      return super.selectById(idSet);
    }

    public override List<Campaign> selectByName(String campaignName) {
      return super.selectByName(campaignName);
    }

    public override List<Campaign> selectByName(Set<String> campaignNames) {
      return super.selectByName(campaignNames);
    }
  }
}