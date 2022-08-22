public without sharing class OpportunitySplitManagerController_ET {
  @AuraEnabled
  public static SplitWrapper getOppSplits(Id oppId) {
    SplitWrapper wrapper = new SplitWrapper();
    OpportunitySplitSelector_ET splitSelector = (OpportunitySplitSelector_ET) Application_ET.Selector.newInstance(
      Opportunity_Split__c.SObjectType
    );
    List<Opportunity_Split__c> splits = splitSelector.selectByOppId(new Set<Id>{ oppId });
    wrapper.listOfOppSplit = splits;
    if (Schema.sObjectType.Opportunity_Split__c.isCreateable()) {
      wrapper.canSplitCreate = true;
    }
    if (Schema.SObjectType.Opportunity_Split__c.isDeletable()) {
      wrapper.canSplitDelete = true;
    }
    return wrapper;
  }

  @AuraEnabled
  public static void deleteOppSplits(List<Id> oppSplitIds) {
    Set<Id> setOfSplitIds = new Set<Id>(oppSplitIds);
    OpportunitySplitSelector_ET splitSelector = (OpportunitySplitSelector_ET) Application_ET.Selector.newInstance(
      Opportunity_Split__c.SObjectType
    );
    try {
      delete splitSelector.selectById(setOfSplitIds);
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  public class SplitWrapper {
    @AuraEnabled
    public List<Opportunity_Split__c> listOfOppSplit { get; set; }
    @AuraEnabled
    public Boolean canSplitCreate { get; set; }
    @AuraEnabled
    public Boolean canSplitDelete { get; set; }
  }
}