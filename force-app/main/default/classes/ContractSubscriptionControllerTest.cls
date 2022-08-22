@IsTest
public class ContractSubscriptionControllerTest {
  static User currentUser = [SELECT id, CurrencyIsoCode FROM User WHERE id = :UserInfo.getUserId()];
  @testsetup
  public static void testSetup() {
    Account testAccount = new Account();
    testAccount.Name = 'Test' + String.valueOf(System.now());
    testAccount.NS_Customer_Internal_ID__c = '75586';
    testAccount.Country__c = 'United Kingdom';
    testAccount.Legal__c = 'Legal Name';
    testAccount.DNBoptimizer__DNB_D_U_N_S_Number__c = '1234567';
    testAccount.currencyIsoCode = currentUser.currencyIsoCode;
    testAccount.VAT_Number__c = '12345';
    testAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Customer')
      .getRecordTypeId();
    testAccount.BillingStreet = 'Test Street';
    testAccount.BillingCity = 'Test City';
    testAccount.BillingPostalCode = '123456';
    testAccount.BillingCountry = 'United Kingdom';
    testAccount.Phone = '12345678';
    testAccount.Industry = 'Others';
    testAccount.PO_Mandatory__c = 'Yes';
    testAccount.Courier__c = 'No';
    testAccount.Platform__c = 'No';
    insert testAccount;
    Opportunity testOpportunity = new Opportunity();
    testOpportunity.AccountId = testAccount.Id;
    testOpportunity.Name = 'Test' + String.valueOf(System.now());
    testOpportunity.StageName = Constants_SL.OPPORTUNITY_STAGE_DISCOVERY;
    testOpportunity.CloseDate = System.today();
    testOpportunity.currencyIsoCode = currentUser.CurrencyIsoCode;
    insert testOpportunity;
    SBQQ__Quote__c quote = new SBQQ__Quote__c(
      SBQQ__Opportunity2__c = testOpportunity.Id,
      SBQQ__Account__c = testAccount.Id,
      CurrencyIsoCode = currentUser.CurrencyIsoCode,
      SBQQ__StartDate__c = System.today(),
      SBQQ__EndDate__c = System.today().addMonths(1),
      SBQQ__Primary__c = true
    );
    insert quote;
    Product2 prod = new Product2(Name = 'UiPath - Orchestrator - Standard', Family = 'Core Product');
    insert prod;
    PricebookEntry pbe = new PricebookEntry(
      Pricebook2Id = Test.getStandardPricebookId(),
      Product2Id = prod.Id,
      UnitPrice = 100,
      IsActive = true,
      currencyIsoCode = currentUser.CurrencyIsoCode
    );
    insert pbe;
  }
  /*public static testMethod void ContractSubscriptionController() {
    SBQQ__Quote__c quote = [SELECT Id, Sbqq__Account__c, CurrencyIsoCode FROM SBQQ__Quote__c LIMIT 1];
    Opportunity testOpportunity = [SELECT Id, CurrencyIsoCode FROM Opportunity LIMIT 1];
    PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
    Order order = DataFactory_SL.createOrder(quote.Id, testOpportunity.Id, false);
    order.currencyIsoCode = currentUser.CurrencyIsoCode;
    insert order;
    OrderItem orderItem = new OrderItem(OrderId = order.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 100);
    orderItem.SBQQ__SubscriptionPricing__c = 'Fixed Price';
    orderItem.License_Codes__c = '674545464';
    insert orderItem;
    Product2 product = [SELECT Id FROM Product2];
    product.productCode = 'UIELAUR0001';
    update product;
    Contract con = new Contract(AccountId = quote.Sbqq__Account__c);
    insert con;
    SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(
      SBQQ__Product__c = product.Id,
      SBQQ__Quantity__c = 1,
      SBQQ__Contract__c = con.Id,
      ELA_End_Date__c = system.today() + 100
    );
    insert subscription;
    ContractSubscriptionController.getContractDetail(con.Id);
    String result = JSON.serialize(ContractSubscriptionController.getSubscription(con.Id));
    ContractSubscriptionController.saveSubscription(result);
  }*/
}