@IsTest
public class BudgetQuoteControllerTest_SL {
  @TestSetup
  private static void makeData() {
    Product2 pro = new Product2(
      Name = 'BudgetQuoteControllerTest_SL ' + String.valueOf((Math.random() * 100) + 1),
      ProductCode = 'VERYCOOL_PRODUCT',
      IsActive = true
    );
    insert new List<Product2>{ pro };

    CPQ_Config__c cs = new CPQ_Config__c();
    cs.Budget_Quote_Products__c = 'VERYCOOL_PRODUCT';
    insert cs;
  }

  @IsTest
  private static void getBudgetQuoteProductsTest() {
    Test.startTest();
    BudgetQuoteController_SL.BudgetQuoteWrapper wrapper = BudgetQuoteController_SL.getBudgetQuoteProducts();
    System.assertEquals(wrapper.productOptions.size(), 1, 'getBudgetQuoteProducts method not working');
    Test.stopTest();
  }
}