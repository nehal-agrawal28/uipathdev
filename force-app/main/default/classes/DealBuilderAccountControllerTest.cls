@IsTest(isParallel=true)
public inherited sharing class DealBuilderAccountControllerTest {
  @TestSetup
  private static void makeData() {
    Account testAccount = DataFactory_CM.createAccount('Customer', false);
    testAccount.Name = 'DealBuilderAccountControllerTest';
    insert testAccount;
  }

  @isTest
  private static void searchTest() {
    Test.startTest();
    List<LookupSearchResult_SL> result = DealBuilderAccountController.search('DealBuilderAccount', new List<String>());
    System.assertEquals(
      [FIND 'DealBuilderAccount*' IN ALL FIELDS RETURNING Account(Id, Name, BillingCountry)][0].size(),
      result.size(),
      'No result found'
    );

    DealBuilderAccountController.getRecentlyViewed();
    Test.stopTest();
  }
}