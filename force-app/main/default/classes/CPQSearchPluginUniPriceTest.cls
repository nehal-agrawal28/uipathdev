@isTest
public class CPQSearchPluginUniPriceTest {
  final static String DEAL_HUB_CUSTOM_PERM = 'Deal_Hub_User';
  final static String USER_PERM_MESSAGE = 'Current user should possess enhanced perm';
  final static String EXPECTED_ELEMENTS_MESSAGE_MESSAGE = 'The actual GTM structures should contain all the expected elements';
  final static String EXPECTED_VS_ACTUAL_MESSAGE = 'The GTM structure elements expected v. actual should be the same';
  final static String OTHER_METHOD_ASSERT_MESSAGE = 'Should return null/false only';
  final static String EXPECTED_NUM_ELEMENTS_MESSAGE = 'Enabled product catalog should contain the expected number of elements';
  final static String EXPECTED_ELEMENTS_MESSAGE = 'Enabled product catalog does not contain the expected elements';
  final static String DISABLED_TYPES_MESSAGE = 'The actual product catalog should not have contained any disabled types';
  final static String NEW_BUSINESS_DEFAULT_MESSAGE = 'When there is no Opportunity.Type the context should be assumed as \'New Business\'';

  public static void setup() {
    //ACCOUNT
    Account accToTest = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, false);
    accToTest.BillingCountry = 'United Kingdom';
    insert accToTest;

    //OPP
    Opportunity oppToTest = DataFactory_SL.createOpportunity(accToTest.Id, true);

    //QUOTE
    SBQQ__Quote__c quoteToTest = DataFactory_SL.createCPQQuote(accToTest.Id, oppToTest.Id, false);
    quoteToTest.Bill_To_Account__c = accToTest.Id;
    insert quoteToTest;
  }

  //unit
  @isTest
  public static void returnsCorrectSearchClauseForZone() {
    setup();
    createCountry();
    SBQQ__Quote__c quoteToTest = [SELECT Id FROM SBQQ__Quote__c];
    CPQSearchPluginUniPrice searchPluginInstance = new CPQSearchPluginUniPrice();
    System.assertEquals(
      true,
      searchPluginInstance.getAdditionalSearchFilters(quoteToTest, null) != null,
      'Search filters should return a where clause'
    );
    System.assertEquals(
      null,
      searchPluginInstance.getAdditionalSuggestFilters(quoteToTest, null),
      OTHER_METHOD_ASSERT_MESSAGE
    );
    System.assertEquals(
      null,
      searchPluginInstance.getFilterDefaultValue(quoteToTest, null),
      OTHER_METHOD_ASSERT_MESSAGE
    );
    System.assertEquals(
      null,
      searchPluginInstance.getInputDefaultValue(quoteToTest, null),
      OTHER_METHOD_ASSERT_MESSAGE
    );
    System.assertEquals(false, searchPluginInstance.isFilterHidden(quoteToTest, null), OTHER_METHOD_ASSERT_MESSAGE);
    System.assertEquals(false, searchPluginInstance.isInputHidden(quoteToTest, null), OTHER_METHOD_ASSERT_MESSAGE);
    System.assertEquals(false, searchPluginInstance.isSearchCustom(quoteToTest, null), OTHER_METHOD_ASSERT_MESSAGE);
    System.assertEquals(false, searchPluginInstance.isSuggestCustom(quoteToTest, null), OTHER_METHOD_ASSERT_MESSAGE);
    System.assertEquals(null, searchPluginInstance.search(quoteToTest, null), OTHER_METHOD_ASSERT_MESSAGE);
    System.assertEquals(null, searchPluginInstance.suggest(quoteToTest, null), OTHER_METHOD_ASSERT_MESSAGE);
    System.assertEquals(
      null,
      searchPluginInstance.getAdditionalSuggestFilters(quoteToTest, null),
      OTHER_METHOD_ASSERT_MESSAGE
    );
  }

  //unit
  @isTest
  public static void itShouldReturnFalseForEnhancedUserContextNullArg() {
    //GIVEN
    Set<String> perms = new Set<String>();

    //WHEN
    Boolean enhancedContext = CPQSearchPluginUniPrice.getEnhancedUserContext(perms);

    //THEN
    System.assertEquals(false, enhancedContext, 'User context should not be \'enhanced\'');
  }

  //unit
  @isTest
  public static void itShouldReturnFalseForEnhancedUserContext() {
    //GIVEN
    Set<String> perms = new Set<String>{ 'CPQ_Admin' };

    //WHEN
    Boolean enhancedContext = CPQSearchPluginUniPrice.getEnhancedUserContext(perms);

    //THEN
    System.assertEquals(false, enhancedContext, 'User context should not be \'enhanced\'');
  }

  //unit
  @isTest
  public static void itShouldReturnTrueForEnhancedUserContext() {
    //GIVEN
    Set<String> perms = new Set<String>{ DEAL_HUB_CUSTOM_PERM };

    //WHEN
    Boolean enhancedContext = CPQSearchPluginUniPrice.getEnhancedUserContext(perms);

    //THEN
    System.assertEquals(true, enhancedContext, 'User context should be \'enhanced\'');
  }

  //unit
  @isTest
  public static void itShouldReturnFalseForNewBusinessContext() {
    //GIVEN
    setup();
    createCountry();
    SBQQ__Quote__c quoteToTest = [SELECT Id, SBQQ__Opportunity2__r.Type FROM SBQQ__Quote__c];
    Opportunity oppToTest = [SELECT Id FROM Opportunity WHERE Id = :quoteToTest.SBQQ__Opportunity2__c];
    oppToTest.Type = Constants_SL.OPPORTUNITY_TYPE_RENEWAL;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update oppToTest;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();
    quoteToTest = [SELECT Id, SBQQ__Opportunity2__r.Type FROM SBQQ__Quote__c];

    //WHEN
    Boolean result = CPQSearchPluginUniPrice.getOppNewBusinessContext(quoteToTest.SBQQ__Opportunity2__r.Type);

    //THEN
    System.assertEquals(false, result, 'Quote new business context should be false');
  }

  //unit
  @isTest
  public static void itShouldReturnTrueForNewBusinessContext() {
    //GIVEN
    setup();
    createCountry();
    SBQQ__Quote__c thisQuote = [SELECT Id, SBQQ__Opportunity2__r.Type FROM SBQQ__Quote__c];
    Opportunity thisOpp = [SELECT Id FROM Opportunity WHERE Id = :thisQuote.SBQQ__Opportunity2__c];
    thisOpp.Type = 'New Business';
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update thisOpp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //WHEN
    Boolean result = CPQSearchPluginUniPrice.getOppNewBusinessContext(thisQuote.SBQQ__Opportunity2__r.Type);

    //THEN
    System.assertEquals(true, result, 'Quote new business context should eval to true');
  }

  //001
  //method
  //standard
  //new business
  @isTest
  public static void itShouldReturnTheEnabledGtmStructuresForStandardUserNewBusinessScenario() {
    //GIVEN
    setup();
    createCountry();
    Set<String> expectedProdCat = new Set<String>{ 'GPS', 'Flex' };
    Set<String> disabledProdCat = new Set<String>{ 'NPS', 'OPS', 'Other' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedProdCat);
    wholeCatalog.addAll(disabledProdCat);
    additionalSetup(wholeCatalog);

    Id accId = [SELECT Id FROM Account LIMIT 1].Id;
    Boolean newBusiness = true;
    Boolean enhancedUser = false;

    //WHEN
    Set<String> actualProdCat = CPQSearchPluginUniPrice.getProductSubCatalog(newBusiness, enhancedUser, accId);

    //THEN
    System.assertEquals(expectedProdCat.size(), actualProdCat.size(), EXPECTED_NUM_ELEMENTS_MESSAGE);
    System.assert(actualProdCat.containsAll(expectedProdCat), EXPECTED_ELEMENTS_MESSAGE);
    Integer returnedActualProdCatSize = actualProdCat.size();
    actualProdCat.removeAll(disabledProdCat);
    System.assertEquals(returnedActualProdCatSize, actualProdCat.size(), DISABLED_TYPES_MESSAGE);
  }

  //002
  //method
  //standard
  //upsell/renewal
  //nps disabled
  @isTest
  public static void itShouldReturnTheEnabledGtmStructuresForStandardUserUpsellRenewalBusinessScenarioNpsDisabled() {
    //GIVEN
    setup();
    createCountry();
    Set<String> expectedProdCat = new Set<String>{ 'GPS', 'Flex' };
    Set<String> disabledProdCat = new Set<String>{ 'OPS', 'Other', 'NPS' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedProdCat);
    wholeCatalog.addAll(disabledProdCat);
    wholeCatalog.remove('NPS');
    additionalSetup(wholeCatalog);

    Id accId = [SELECT Id FROM Account LIMIT 1].Id;
    Boolean newBusiness = false;
    Boolean enhancedUser = false;

    //WHEN
    Set<String> actualProdCat = CPQSearchPluginUniPrice.getProductSubCatalog(newBusiness, enhancedUser, accId);

    //THEN
    System.assertEquals(expectedProdCat.size(), actualProdCat.size(), EXPECTED_NUM_ELEMENTS_MESSAGE);
    System.assert(actualProdCat.containsAll(expectedProdCat), EXPECTED_ELEMENTS_MESSAGE);
    Integer returnedActualProdCatSize = actualProdCat.size();
    actualProdCat.removeAll(disabledProdCat);
    System.assertEquals(returnedActualProdCatSize, actualProdCat.size(), DISABLED_TYPES_MESSAGE);
  }

  //003
  //method
  //standard
  //upsell/renewal
  //nps enabled
  @isTest
  public static void itShouldReturnTheEnabledGtmStructuresForStandardUserUpsellRenewalBusinessScenarioNpsEnabled() {
    //GIVEN
    setup();
    Set<String> expectedProdCat = new Set<String>{ 'GPS', 'Flex', 'NPS' };
    Set<String> disabledProdCat = new Set<String>{ 'OPS', 'Other' };
    additionalSetup(expectedProdCat);
    createCountry();
    Id accId = [SELECT Id FROM Account LIMIT 1].Id;
    Boolean newBusiness = false;
    Boolean enhancedUser = false;

    //WHEN
    Set<String> actualProdCat = CPQSearchPluginUniPrice.getProductSubCatalog(newBusiness, enhancedUser, accId);

    //THEN
    System.assertEquals(expectedProdCat.size(), actualProdCat.size(), EXPECTED_NUM_ELEMENTS_MESSAGE);
    System.assert(actualProdCat.containsAll(expectedProdCat), EXPECTED_ELEMENTS_MESSAGE);
    Integer returnedActualProdCatSize = actualProdCat.size();
    actualProdCat.removeAll(disabledProdCat);
    System.assertEquals(returnedActualProdCatSize, actualProdCat.size(), DISABLED_TYPES_MESSAGE);
  }

  //004
  //method
  //enhanced
  //new business
  @isTest
  public static void itShouldReturnTheEnabledGtmStructuresForEnhancedUserNewBusinessScenario() {
    //GIVEN
    setup();
    createCountry();
    Set<String> expectedProdCat = new Set<String>{ 'GPS', 'Flex', 'NPS' };
    Set<String> disabledProdCat = new Set<String>{ 'OPS', 'Other' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedProdCat);
    wholeCatalog.addAll(disabledProdCat);
    additionalSetup(wholeCatalog);

    Id accId = [SELECT Id FROM Account LIMIT 1].Id;
    Boolean newBusiness = true;
    Boolean enhancedUser = true;

    //WHEN
    Set<String> actualProdCat = CPQSearchPluginUniPrice.getProductSubCatalog(newBusiness, enhancedUser, accId);

    //THEN
    System.assertEquals(expectedProdCat.size(), actualProdCat.size(), EXPECTED_NUM_ELEMENTS_MESSAGE);
    System.assert(actualProdCat.containsAll(expectedProdCat), EXPECTED_ELEMENTS_MESSAGE);
    Integer returnedActualProdCatSize = actualProdCat.size();
    actualProdCat.removeAll(disabledProdCat);
    System.assertEquals(returnedActualProdCatSize, actualProdCat.size(), DISABLED_TYPES_MESSAGE);
  }

  //005
  //method
  //enhanced
  //upsell/renewal
  @isTest
  public static void itShouldReturnTheEnabledGtmStructuresForEnhancedUserUpsellRenewalBusinessScenario() {
    //GIVEN
    setup();
    createCountry();
    Set<String> expectedProdCat = new Set<String>{ 'GPS', 'Flex', 'NPS', 'OPS' };
    Set<String> disabledProdCat = new Set<String>{ 'Other' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedProdCat);
    wholeCatalog.addAll(disabledProdCat);
    additionalSetup(wholeCatalog);

    Id accId = [SELECT Id FROM Account LIMIT 1].Id;
    Boolean newBusiness = false;
    Boolean enhancedUser = true;

    //WHEN
    Set<String> actualProdCat = CPQSearchPluginUniPrice.getProductSubCatalog(newBusiness, enhancedUser, accId);

    //THEN
    System.assertEquals(expectedProdCat.size(), actualProdCat.size(), EXPECTED_NUM_ELEMENTS_MESSAGE);
    System.assert(actualProdCat.containsAll(expectedProdCat), EXPECTED_ELEMENTS_MESSAGE);
    Integer returnedActualProdCatSize = actualProdCat.size();
    actualProdCat.removeAll(disabledProdCat);
    System.assertEquals(returnedActualProdCatSize, actualProdCat.size(), DISABLED_TYPES_MESSAGE);
  }

  /*
   *Tests that follow are necessarily brittle in that they parse a string (the SOQL WHERE clause)
   *Ideally CPQSearchPluginUniPrice.cls would be refactored to make its code units more atomic and testable using Apex types vs. string parsing
   *This is unfortunately not possible given time constraints at this point
   */
  //006
  //where
  //enhanced
  //new business
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForEnhancedUserNewBusinessScenario() {
    //GIVEN
    Set<String> expectedGtmStructures = new Set<String>{ 'Flex', 'GPS', 'NPS' };
    setup();
    createCountry();

    //Create a user
    User testUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);
    //elevate perm
    addEnhancedCustomPerm(testUser.Id);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.OwnerId = testUser.Id;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //force @future to process
    Test.startTest();
    Test.stopTest();
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testUser) {
      System.assertEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGtmStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGtmStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //007
  //where
  //enhanced
  //renewal
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForEnhancedUserRenewalScenario() {
    //GIVEN
    Set<String> expectedGtmStructures = new Set<String>{ 'Flex', 'GPS', 'NPS', 'OPS' };
    setup();
    createCountry();

    //Create a user
    User testUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);
    //elevate perm
    addEnhancedCustomPerm(testUser.Id);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_RENEWAL; //Renewal
    opp.OwnerId = testUser.Id;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    SBQQ__Quote__c requote = [SELECT Id, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Type FROM SBQQ__Quote__c LIMIT 1];
    System.debug('TEST METHOD: ' + requote.SBQQ__Opportunity2__r.Type);

    //force @future to process
    Test.startTest();
    Test.stopTest();
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testUser) {
      requote = [SELECT Id, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Type FROM SBQQ__Quote__c LIMIT 1];
      System.debug('TEST METHOD 2: ' + requote.SBQQ__Opportunity2__r.Type);
      System.assertEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGtmStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGtmStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //008
  //where
  //enhanced
  //upsell
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForEnhancedUserUpsellScenario() {
    //GIVEN
    Set<String> expectedGtmStructures = new Set<String>{ 'Flex', 'GPS', 'NPS', 'OPS' };
    setup();
    createCountry();

    //Create a user
    User testUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);
    //elevate perm
    addEnhancedCustomPerm(testUser.Id);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_UPSELL; //Upsell
    opp.OwnerId = testUser.Id;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //force @future to process
    Test.startTest();
    Test.stopTest();
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testUser) {
      System.assertEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGtmStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGtmStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //009
  //where
  //standard
  //new business
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForStandardUserNewBusinessScenario() {
    //GIVEN
    setup();
    createCountry();
    Set<String> expectedGtmStructures = new Set<String>{ 'Flex', 'GPS' };

    //Create a user
    User testUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);

    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testUser) {
      System.assertNotEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGtmStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGtmStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //010
  //where
  //standard
  //renewal
  //nps disabled
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForStandardUserRenewalScenarioNpsDisabled() {
    //GIVEN

    setup();
    createCountry();
    Set<String> expectedGtmStructures = new Set<String>{ 'Flex', 'GPS' };
    Set<String> disabledGtmStrcutures = new Set<String>{ 'NPS', 'OPS', 'Other' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedGtmStructures);
    wholeCatalog.addAll(disabledGtmStrcutures);
    wholeCatalog.remove('NPS');
    additionalSetup(wholeCatalog);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_RENEWAL; //Renewal
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //Create a user
    User testUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);

    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testUser) {
      System.assertNotEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGtmStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGtmStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //011
  //where
  //standard
  //renewal
  //nps enabled
  public static void itShouldReturnTheCorrectWhereClauseForStandardUserRenewalScenarioNpsEnabled() {
    //GIVEN

    setup();
    createCountry();
    Set<String> expectedGtmStructures = new Set<String>{ 'Flex', 'GPS', 'NPS' };
    Set<String> disabledGtmStrcutures = new Set<String>{ 'OPS', 'Other' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedGtmStructures);
    wholeCatalog.addAll(disabledGtmStrcutures);
    additionalSetup(wholeCatalog);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_RENEWAL; //Renewal
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //Create a user
    User testUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);

    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testUser) {
      System.assertNotEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGtmStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGtmStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //012
  //where
  //standard
  //upsell
  //nps disabled
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForStandardUserUpsellScenarioNpsDisabled() {
    //GIVEN
    setup();
    createCountry();
    Set<String> expectedGtmStructures = new Set<String>{ 'Flex', 'GPS' };
    Set<String> disabledGtmStrcutures = new Set<String>{ 'NPS', 'OPS', 'Other' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedGtmStructures);
    wholeCatalog.addAll(disabledGtmStrcutures);
    wholeCatalog.remove('NPS');
    additionalSetup(wholeCatalog);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_UPSELL; //Upsell
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //Create a user
    User testUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);

    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testUser) {
      System.assertNotEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGtmStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGtmStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //013
  //where
  //standard
  //upsell
  // nps enabled
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForStandardUserUpsellScenarioNpsEnabled() {
    //GIVEN
    setup();
    createCountry();
    Set<String> expectedGtmStructures = new Set<String>{ 'Flex', 'GPS', 'NPS' };
    Set<String> disabledGtmStrcutures = new Set<String>{ 'OPS', 'Other' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedGtmStructures);
    wholeCatalog.addAll(disabledGtmStrcutures);
    additionalSetup(wholeCatalog);

    //Create a user
    User testUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_UPSELL; //Upsell
    opp.OwnerId = testUser.Id;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testUser) {
      System.assertNotEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGtmStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGtmStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //014
  //where
  //enhanced
  //new business
  //no countries
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForEnhancedUserNewBusinessScenarioNoCountries() {
    //GIVEN
    setup();
    Set<String> expectedGStructures = new Set<String>{ 'Flex', 'GPS', 'NPS' };

    //Create a user
    User testThisUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);
    //elevate perm
    addEnhancedCustomPerm(testThisUser.Id);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.OwnerId = testThisUser.Id;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //force @future to process
    Test.startTest();
    Test.stopTest();
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testThisUser) {
      System.assertEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //015
  //where
  //enhanced
  //renewal
  //no countries
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForEnhancedUserRenewalScenarioNoCountries() {
    //GIVEN
    setup();
    Set<String> expecGtmStructures = new Set<String>{ 'Flex', 'GPS', 'NPS', 'OPS' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expecGtmStructures);
    additionalSetup(wholeCatalog);

    //Create a user
    User testUserEn = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);
    //elevate perm
    addEnhancedCustomPerm(testUserEn.Id);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_RENEWAL; //Renewal
    opp.OwnerId = testUserEn.Id;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //force @future to process
    Test.startTest();
    Test.stopTest();
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testUserEn) {
      System.assertEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expecGtmStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expecGtmStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //016
  //where
  //enhanced
  //upsell
  //no countries
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForEnhancedUserUpsellScenarioNoCountries() {
    //GIVEN
    setup();
    Set<String> expGtmStructures = new Set<String>{ 'Flex', 'GPS', 'NPS', 'OPS' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expGtmStructures);
    additionalSetup(wholeCatalog);

    //Create a user
    User testThisUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);
    //elevate perm
    addEnhancedCustomPerm(testThisUser.Id);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_UPSELL; //Upsell
    opp.OwnerId = testThisUser.Id;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //force @future to process
    Test.startTest();
    Test.stopTest();
    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testThisUser) {
      System.assertEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expGtmStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expGtmStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //017
  //where
  //standard
  //new business
  //no countries
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForStandardUserNewBusinessScenarioNoCountries() {
    //GIVEN
    setup();
    Set<String> expectedStructures = new Set<String>{ 'Flex', 'GPS' };

    //Create a user
    User testStdUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);

    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testStdUser) {
      System.assertNotEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //018
  //where
  //standard
  //renewal
  //no countries
  //nps disabled
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForStandardUserRenewalScenarioNoCountriesNpsDisabled() {
    //GIVEN
    setup();
    Set<String> expectedStructure = new Set<String>{ 'Flex', 'GPS' };
    Set<String> disabledGoToMarketStructures = new Set<String>{ 'NPS', 'OPS', 'OTHER' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedStructure);
    wholeCatalog.addAll(disabledGoToMarketStructures);
    wholeCatalog.remove('NPS');
    additionalSetup(wholeCatalog);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_RENEWAL; //Renewal
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //Create a user
    User testStandardUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);

    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testStandardUser) {
      System.assertNotEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedStructure.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedStructure), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //019
  //where
  //standard
  //renewal
  //no countries
  //nps enabled
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForStandardUserRenewalScenarioNoCountriesNpsEnabled() {
    //GIVEN
    setup();
    Set<String> expectedStructure = new Set<String>{ 'Flex', 'GPS', 'NPS' };
    Set<String> disabledGoToMarketStructures = new Set<String>{ 'OPS', 'OTHER' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedStructure);
    wholeCatalog.addAll(disabledGoToMarketStructures);
    additionalSetup(wholeCatalog);

    //Create a user
    User testStandardUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_RENEWAL; //Renewal
    opp.OwnerId = testStandardUser.Id;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testStandardUser) {
      System.assertNotEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedStructure.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedStructure), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //020
  //where
  //standard
  //upsell
  //no countries
  //nps disabled
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForStandardUserUpsellScenarioNoCountriesNpsDisabled() {
    //GIVEN
    setup();
    Set<String> expectedGoToMarketStructures = new Set<String>{ 'Flex', 'GPS' };
    Set<String> disabledGoToMarketStructures = new Set<String>{ 'NPS', 'OPS', 'OTHER' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedGoToMarketStructures);
    wholeCatalog.addAll(disabledGoToMarketStructures);
    wholeCatalog.remove('NPS');
    additionalSetup(wholeCatalog);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_UPSELL; //Upsell
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    //Create a user
    User testThisStandardUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);

    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testThisStandardUser) {
      System.assertNotEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGoToMarketStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGoToMarketStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  //021
  //where
  //standard
  //upsell
  //no countries
  //nps enabled
  @isTest
  public static void itShouldReturnTheCorrectWhereClauseForStandardUserUpsellScenarioNoCountriesNpsEnabled() {
    //GIVEN
    setup();
    Set<String> expectedGoToMarketStructures = new Set<String>{ 'Flex', 'GPS', 'NPS' };
    Set<String> disabledGoToMarketStructures = new Set<String>{ 'OPS', 'OTHER' };
    Set<String> wholeCatalog = new Set<String>();
    wholeCatalog.addAll(expectedGoToMarketStructures);
    wholeCatalog.addAll(disabledGoToMarketStructures);
    additionalSetup(wholeCatalog);

    //Create a user
    User testThisStandardUser = DataFactory_SL.createUser('Test', 'User', Constants.STANDARD_USER_PROFILE, true);

    Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
    opp.Type = Constants_Sl.OPPORTUNITY_TYPE_UPSELL; //Upsell
    opp.OwnerId = testThisStandardUser.Id;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c];
    Map<String, Object> fieldValuesMap = new Map<String, Object>();
    CPQSearchPluginUniPrice searchPlugin = new CPQSearchPluginUniPrice();

    //WHEN
    String whereClause = '';
    System.runAs(testThisStandardUser) {
      System.assertNotEquals(true, FeatureManagement.checkPermission(DEAL_HUB_CUSTOM_PERM), USER_PERM_MESSAGE);
      whereClause = searchPlugin.getAdditionalSearchFilters(quote, fieldValuesMap);
    }
    Set<String> actualGtmStructures = getGtmStructuresFromString(whereClause);

    //THEN
    System.assertEquals(expectedGoToMarketStructures.size(), actualGtmStructures.size(), EXPECTED_VS_ACTUAL_MESSAGE);
    System.assert(actualGtmStructures.containsAll(expectedGoToMarketStructures), EXPECTED_ELEMENTS_MESSAGE_MESSAGE);
  }

  /*
  *Unpackaed VR prevents execution - Opp.Type_cannot_be_blank
  //022
  @isTest
  public static void itShouldReturnNewBusinessContextForNullOppType() {
    setup();
    //GIVEN
    Opportunity opp = [SELECT Type FROM Opportunity LIMIT 1];
    opp.Type = '';
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__r.Type FROM SBQQ__Quote__c LIMIT 1];

    //WHEN
    Boolean isNewBusiness = CPQSearchPluginUniPrice.getOppNewBusinessContext(quote.SBQQ__Opportunity2__r.Type);

    //THEN
    System.assertEquals(
      true,
      isNewBusiness,
      NEW_BUSINESS_DEFAULT_MESSAGE
    );
  }*/

  //023
  @isTest
  public static void itShouldReturnNewBusinessContextForNonRenewalUpsellOppTypes() {
    //GIVEN
    setup();
    Opportunity opp = [SELECT Type FROM Opportunity LIMIT 1];
    opp.Type = 'Test Type';
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    update opp;
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__r.Type FROM SBQQ__Quote__c LIMIT 1];

    //WHEN
    Boolean isNewBusiness = CPQSearchPluginUniPrice.getOppNewBusinessContext(quote.SBQQ__Opportunity2__r.Type);

    //THEN
    System.assertEquals(true, isNewBusiness, NEW_BUSINESS_DEFAULT_MESSAGE);
  }

  /*
   *UTILS
   */
  private static void createCountry() {
    Country__c cntry = new Country__c(Country_name__c = 'United Kingdom', zone__c = 'Zone1');
    insert cntry;
  }

  @future
  private static void addEnhancedCustomPerm(Id userId) {
    PermissionSet permSet = new PermissionSet(Name = 'Deal_Hub_Test_PS', Label = 'Deal Hub Test PS');
    insert permSet;

    SetupEntityAccess setupEntityAccess = new SetupEntityAccess(
      ParentId = permSet.Id,
      SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = :DEAL_HUB_CUSTOM_PERM LIMIT 1]
      .Id
    );

    PermissionSetAssignment permSetAssignment = new PermissionSetAssignment(
      AssigneeId = userId,
      PermissionSetId = permSet.Id
    );

    insert new List<SObject>{ setupEntityAccess, permSetAssignment };
  }

  private static Set<String> getGtmStructuresFromString(String whereClause) {
    List<SOBjectField> fieldRegister = new List<SObjectField>{
      //Product2.Visibility_Permission__c, - non-packaged
      Product2.GTM_Structure__c
    };
    Set<String> result = new Set<String>();

    String startStr = 'Product2.GTM_Structure__c IN (';
    String endStr = ') AND Product2.Visibility_Permission__c';
    Integer startPos = whereClause.indexOf(startStr) + 30;
    Integer endPos = whereClause.indexOf(endStr);
    String targetStr = whereClause.mid(startPos, endPos - startPos);
    List<String> temp = targetStr.split(',');

    for (String s : temp) {
      String strippedStr = s.trim().remove('\'');
      result.add(strippedStr);
    }

    return result;
  }

  private static void createProds(Set<String> gtms) {
    List<Product2> prodsToInsert = new List<Product2>();
    for (String gtm : gtms) {
      Product2 prod = new Product2(
        Name = gtm,
        GTM_Structure__c = gtm,
        IsActive = true,
        ProductCode = gtm,
        SBQQ__PricingMethod__c = 'List',
        SBQQ__QuantityEditable__c = true,
        SBQQ__SubscriptionPricing__c = 'Fixed Price',
        SBQQ__SubscriptionTerm__c = 12,
        SBQQ__SubscriptionType__c = 'Renewable'
      );
      prodsToInsert.add(prod);
    }
    insert prodsToInsert;
  }

  private static Id createContract(Id accId) {
    Contract gtmContract = new Contract(
      Name = 'Test',
      AccountId = accId,
      StartDate = Date.today(),
      EndDate = Date.today().addDays(364)
    );
    insert gtmContract;
    return gtmContract.Id;
  }

  private static void createSubs(Id accId, Id conId) {
    List<SBQQ__Subscription__c> subsToInsert = new List<SBQQ__Subscription__c>();
    for (Product2 prod : [SELECT Id FROM Product2]) {
      subsToInsert.add(
        new SBQQ__Subscription__c(
          SBQQ__Account__c = accId,
          SBQQ__Quantity__c = 1,
          SBQQ__Contract__c = conId,
          SBQQ__Product__c = prod.Id
        )
      );
    }
    insert subsToInsert;
  }

  private static void additionalSetup(Set<String> gtms) {
    Id accId = [SELECT Id FROM Account LIMIT 1].Id;
    Id conId = createContract(accId);
    createProds(gtms);
    createSubs(accId, conId);
  }
}