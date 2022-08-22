/**
 * @AUTHOR: UIPath
 * @DATE: 07/12/2021
 * @DESCRIPTION: This is territory2 object service class
 */
public inherited sharing class TerritoriesService_ET {
  public void setRecalculateCompensationFlag(List<Territory2> territoriesList, Map<Id, Territory2> territoriesMap) {
    for (Territory2 terr : territoriesList) {
      Territory2 oldTerr;
      if (territoriesMap != null) {
        oldTerr = territoriesMap.get(terr.Id);
      }
      if (
        oldTerr != null &&
        !terr.Recalculate_Compensation__c &&
        (terr.Partner_Manager_Team_Credit__c != oldTerr.Partner_Manager_Team_Credit__c ||
        terr.ParentTerritory2Id != oldTerr.ParentTerritory2Id)
      ) {
        terr.Recalculate_Compensation__c = true;
      }
    }
  }

  public void populateAVPRVP(List<Territory2> territories) {
    Map<String, Territory2> areaMap = new Map<String, Territory2>();
    Map<String, Territory2> regionMap = new Map<String, Territory2>();
    Map<String, Territory2> geoMap = new Map<String, Territory2>();
    for (Territory2 terr : territories) {
      if (terr.Sales_Area__c == true) {
        areaMap.put(terr.Area__c, terr);
      } else if (terr.Sales_Region__c == true) {
        regionMap.put(terr.Region__c, terr);
      } else if (terr.Sales_Geo__c == true) {
        geoMap.put(terr.Ultimate_Geo__c, terr);
      }
    }

    //removed the sales territory check to update all the associated territories in the heirarchy not just sales.
    Territory2sSelector_ET territorySelector = (Territory2sSelector_ET) Application_ET.Selector.newInstance(
      Territory2.SObjectType
    );
    List<Territory2> salesTerritories = territorySelector.selectSalesTerritoryByAreaOrRegion(
      areaMap.keySet(),
      regionMap.keySet(),
      geoMap.keySet()
    );

    for (Territory2 salesTerritory : salesTerritories) {
      Territory2 areaTerr = areaMap.get(salesTerritory.Area__c);

      if (areaTerr != null) {
        salesTerritory.AVP_Id__c = areaTerr.AVP_Id__c;
        salesTerritory.AVP_Name__c = areaTerr.AVP_Name__c;
      }

      Territory2 regionTerr = regionMap.get(salesTerritory.Region__c);
      if (regionTerr != null) {
        salesTerritory.RVP_Id__c = regionTerr.RVP_Id__c;
        salesTerritory.RVP_Name__c = regionTerr.RVP_Name__c;
      }

      Territory2 geoTerr = geoMap.get(salesTerritory.Ultimate_Geo__c);
      if (geoTerr != null) {
        salesTerritory.GVP_Id__c = geoTerr.GVP_Id__c;
        salesTerritory.GVP_Name__c = geoTerr.GVP_Name__c;
      }
    }

    if (!salesTerritories.isEmpty()) {
      Database.update(salesTerritories, false);
    }
  }
}