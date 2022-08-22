/**
 * @AUTHOR: UIPath
 * @DATE: 07/02/2022
 * @DESCRIPTION: This class contains utility methods which used in multiple classes
 */
public inherited sharing class Utility_ET {
  public static ETM_Setting__mdt getSetting(String developerName) {
    ETM_Setting__mdt setting;
    if (!String.isBlank(developerName)) {
      List<ETM_Setting__mdt> metadataList = [
        SELECT Label, DeveloperName, Value__c
        FROM ETM_Setting__mdt
        WHERE DeveloperName = :developerName
      ];
      if (!metadataList.isEmpty()) {
        setting = metadataList[0];
      }
    }
    return setting;
  }
}