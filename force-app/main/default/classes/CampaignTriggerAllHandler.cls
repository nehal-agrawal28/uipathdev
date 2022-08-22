/********************************************************************************************************
*    Handler Name:  CampaignTriggerAllHandler.cls
*    Author: Mirela Chituc (mirela.chituc@uipath.com) 
*    Date:  10/14/2019
*    
*    Trigger: CampaignTriggerAll.trigger
*    Test class: CampaignTriggerAllHandlerTest.cls
********************************************************************************************************/

public without sharing class CampaignTriggerAllHandler {
    
    //Handler for before insert methods
    public void onBeforeInsert(list<Campaign> newList , map<id, Campaign> newMap) {
        SetUpRegionOnCampaign(newList, newMap, 'insert');
    }
    //Handler for after insert methods
    public void onAfterInsert(list<Campaign> newList , map<id, Campaign> newMap) {
        
       
    }
    //Handler for before Update methods
    public void onBeforeUpdate(list<Campaign> newList, map<id, Campaign> newMap , map<id, Campaign> oldMap) {
        SetUpRegionOnCampaign(newList, oldMap, 'update');
    }
    //Handler for after Update methods
    public void onAfterUpdate(list<Campaign> newList, map<id, Campaign> newMap,  map<id, Campaign> oldMap) {
        
    }

    //Handler for before Deletes methods
    //public void onBeforeDelete(list<Campaign> oldList , map<id, Campaign> oldMap) {

    //}
    //Handler for after Deletes methods
    //public void onAfterDelete(list<Campaign> oldList , map<id, Campaign> oldMap) {
        
    //}
    
    
    // Sets up the Campaign_Geo__c field based on Country__c using corresponding values from ROW_Country__mdt
    private void SetUpRegionOnCampaign(list<Campaign> CampaignList, map<id, Campaign> CampaignOldMap, String triggerAction){
        
        // Get ROW_Country__mdt values and create a map with Country as key and record as value
        List<ROW_Country__mdt> Countries = [SELECT Country__c, Region__c, Area__c, Territory__c FROM ROW_Country__mdt];
        Map<String, ROW_Country__mdt> CountriesMap = new Map<String, ROW_Country__mdt>();
        
        for(ROW_Country__mdt rcountry: Countries) {
            CountriesMap.put(rCountry.Country__c, rcountry);
        } 
        
        // for each campaign find the Region__c corresponding to the Campaign.Campaign_Country__c field
        for(Campaign ca: CampaignList) {
            if(!String.isEmpty(ca.Campaign_Country__c) && CountriesMap.containsKey(ca.Campaign_Country__c)) {
                ca.Campaign_Geo__c = CountriesMap.get(ca.Campaign_Country__c).Region__c;
            } else {
                if(ca.Campaign_Geo__c != 'United States')
                    ca.Campaign_Geo__c = 'AMER';
            }
        }            
        
    }
}