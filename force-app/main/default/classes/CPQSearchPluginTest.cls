@isTest
public class CPQSearchPluginTest {
  @testSetup
  public static void setup() {
    DataFactory.createSampleQuoteWithAssociations('CPQSearchPluginTest');
    Country__c cntry = new Country__c(Country_name__c = 'Australia', zone__c = 'Zone3');
    insert cntry;
  }

  @isTest
  public static void returnsCorrectSearchClauseForZone() {
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    CPQSearchPlugin searchPlugin = new CPQSearchPlugin();
    System.assertEquals(true, searchPlugin.getAdditionalSearchFilters(quote, null) != null);
    System.assertEquals(searchPlugin.getAdditionalSuggestFilters(quote, null), null);
    System.assertEquals(searchPlugin.getFilterDefaultValue(quote, null), null);
    System.assertEquals(searchPlugin.getInputDefaultValue(quote, null), null);
    System.assertEquals(searchPlugin.isFilterHidden(quote, null), false);
    System.assertEquals(searchPlugin.isInputHidden(quote, null), false);
    System.assertEquals(searchPlugin.isSearchCustom(quote, null), false);
    System.assertEquals(searchPlugin.isSuggestCustom(quote, null), false);
    System.assertEquals(searchPlugin.search(quote, null), null);
    System.assertEquals(searchPlugin.suggest(quote, null), null);
    System.assertEquals(searchPlugin.getAdditionalSuggestFilters(quote, null), null);
  }
}