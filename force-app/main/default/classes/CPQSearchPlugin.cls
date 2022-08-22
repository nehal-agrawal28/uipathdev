/**
 *  @author Girish Lakshmanan
 * @description CPQ search plugin to allow for more flexible CPQ QLE Prod search based on Quote context
 */
global without sharing class CPQSearchPlugin implements SBQQ.ProductSearchPlugin {
  global CPQSearchPlugin() {
  }

  /**
   *
   *
   * @param quote model of current Quote
   * @param fieldValuesMap search Criteria name value pairs
   *
   * @return WHERE clause with additional search criteria - please be careful with the brackets!!!
   */
  global String getAdditionalSearchFilters(SObject quote, Map<String, Object> fieldValuesMap) {
    String countryFilter = null;
    String zonalFilter = null;
    String permissionFilter = null;
    Set<Id> customPermissionIds = new Set<Id>();
    Set<String> customPermissions = new Set<String>();

    // Custom permission filter
    for (SetupEntityAccess entity : [
      SELECT SetupEntityId
      FROM SetupEntityAccess
      WHERE
        SetupEntityType = 'CustomPermission'
        AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId())
    ]) {
      // SetupEntityId is a polymorphic lookup
      customPermissionIds.add(entity.SetupEntityId);
    }
    for (CustomPermission cp : [SELECT DeveloperName FROM CustomPermission WHERE Id IN :customPermissionIds]) {
      customPermissions.add(cp.DeveloperName);
    }
    // prettier-ignore
    permissionFilter = 
    ' (' + 
        ' (Product2.Visibility_Permission__c IN ( \'' +  String.join(new List<String>(customPermissions), '\',\'') + '\' ) )' + 
        ' OR ' + 
        ' (Product2.Visibility_Permission__c = null)' + 
    ' )';
    // Zone and Country filter
    String country = [SELECT Id, Bill_To_Account__r.BillingCountry FROM SBQQ__Quote__c WHERE Id = :quote.Id]
    .Bill_To_Account__r.BillingCountry;
    List<Country__c> countries = [SELECT zone__c FROM Country__c WHERE Country_Name__c = :country LIMIT 1];

    //Use Country to Query Custom metadata and pull the zone out
    if (countries.isEmpty() || countries.get(0).zone__c == null) {
      return permissionFilter;
    }

    String currentZone = countries.get(0).zone__c;
    zonalFilter = ' ((Product2.Zones__c = \'' + currentZone + '\') OR (Product2.Zones__c = null))';
    countryFilter = ' ((Product2.Countries__c includes ( \'' + country + '\')) OR (Product2.Countries__c = null))';

    return ' (' + zonalFilter + ' AND ' + countryFilter + ' AND ' + permissionFilter + ' )';
  }

  global String getAdditionalSuggestFilters(SObject so, Map<String, Object> ma) {
    return null;
  }

  global String getFilterDefaultValue(SObject so, String st) {
    return null;
  }

  global String getInputDefaultValue(SObject so, String st) {
    return null;
  }

  global Boolean isFilterHidden(SObject so, String st) {
    return false;
  }

  global Boolean isInputHidden(SObject so, String st) {
    return false;
  }

  global Boolean isSearchCustom(SObject so, Map<String, Object> ma) {
    return false;
  }

  global Boolean isSuggestCustom(SObject so, Map<String, Object> ma) {
    return false;
  }

  global List<PricebookEntry> search(SObject quote, Map<String, Object> ma) {
    return null;
  }

  global List<PricebookEntry> suggest(SObject so, Map<String, Object> ma) {
    return null;
  }
}