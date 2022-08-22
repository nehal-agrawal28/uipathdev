@IsTest
private class CPQRenewalsUpliftTest_SL {
  @TestSetup
  private static void makeData() {
    // Account
    Account acc = DataFactory_CM.createAccount('Customer', false);
    acc.Name = 'CPQRenewalsUpliftTest_SL Account';
    acc.SBQQ__RenewalPricingMethod__c = 'Uplift';
    insert acc;
    // Contracts
    createContracts(25, 25, acc.Id);
  }

  private static void createContracts(Integer contractCount, Integer subCount, Id accountId) {
    List<Contract> conList = new List<Contract>();
    List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();

    for (Integer i = 0; i < contractCount; i++) {
      Contract con = new Contract(AccountId = accountId);
      conList.add(con);
    }
    insert conList;

    for (Integer i = 0; i < conList.size(); i++) {
      for (Integer j = 0; j < subCount; j++) {
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
          SBQQ__Contract__c = conList[i].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionStartDate__c = System.today(),
          SBQQ__SubscriptionEndDate__c = System.today().addYears(1),
          SBQQ__NetPrice__c = 1000,
          SBQQ__ListPrice__c = 1500
        );
        subList.add(sub);
      }
    }
    insert subList;
  }

  @IsTest
  private static void applyRenewalUpliftTest() {
    Map<Id, Contract> conMap = new Map<Id, Contract>(
      [SELECT Id, AccountId FROM Contract WHERE Account.Name = 'CPQRenewalsUpliftTest_SL Account']
    );
    Map<Id, SBQQ__Subscription__c> subMap = new Map<Id, SBQQ__Subscription__c>(
      [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c IN :conMap.keySet()]
    );

    Test.startTest();

    RenewalUpliftManagementController.setAccountMethodUplift(new List<String>{ conMap.values().get(0).AccountId });
    RenewalUpliftManagementController.applyRenewalUplift((List<String>) new List<Id>(conMap.keySet()), true);

    Test.stopTest();

    List<Contract> conList = ((ContractsSelector_SL) Application_SL.Selector.newInstance(Contract.SObjectType))
      .selectById(conMap.keySet(), false);
    System.assertEquals(true, conList[0].SBQQ__RenewalUpliftRate__c > 0, 'Uplift was not applied on Contract');

    List<SBQQ__Subscription__c> subList = ((SubscriptionSelector_SL) Application_SL.Selector.newInstance(
        SBQQ__Subscription__c.SObjectType
      ))
      .selectById(subMap.keySet(), false);
    System.assertEquals(true, subList[0].SBQQ__RenewalUpliftRate__c > 0, 'Uplift was not applied on Subscription');
  }

  @IsTest
  private static void removeRenewalUpliftTest() {
    Map<Id, Contract> conMap = new Map<Id, Contract>(
      [SELECT Id, AccountId FROM Contract WHERE Account.Name = 'CPQRenewalsUpliftTest_SL Account']
    );
    Map<Id, SBQQ__Subscription__c> subMap = new Map<Id, SBQQ__Subscription__c>(
      [SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c IN :conMap.keySet()]
    );

    Test.startTest();

    RenewalUpliftManagementController.removeRenewalUplift((List<String>) new List<Id>(conMap.keySet()));

    Test.stopTest();

    List<Contract> conList = ((ContractsSelector_SL) Application_SL.Selector.newInstance(Contract.SObjectType))
      .selectById(conMap.keySet(), false);
    System.assertEquals(null, conList[0].SBQQ__RenewalUpliftRate__c, 'Uplift was not removed from Contract');

    List<SBQQ__Subscription__c> subList = ((SubscriptionSelector_SL) Application_SL.Selector.newInstance(
        SBQQ__Subscription__c.SObjectType
      ))
      .selectById(subMap.keySet(), false);
    System.assertEquals(null, subList[0].SBQQ__RenewalUpliftRate__c, 'Uplift was not removed from Subscription');
  }

  @IsTest
  private static void getUpliftDataTest() {
    Map<Id, Contract> conMap = new Map<Id, Contract>(
      [SELECT Id FROM Contract WHERE Account.Name = 'CPQRenewalsUpliftTest_SL Account']
    );

    Test.startTest();

    try {
      RenewalUpliftManagementController.getUpliftData(null);
    } catch (Exception e) {
    }
    RenewalUpliftManagementController.DealBuilderManageUpliftWrapper wrapper = RenewalUpliftManagementController.getUpliftDataForDealBuilder(
      (List<String>) new List<Id>(conMap.keySet())
    );
    System.assertEquals(true, wrapper.upliftGeoConfig != null, 'CPQ_Renewal_Uplift__mdt is not setup correctly');

    Test.stopTest();
  }

  @IsTest
  private static void negativeRenewalUpliftTest() {
    Test.startTest();

    try {
      RenewalUpliftManagementController.applyRenewalUplift(new List<String>(), false);
      RenewalUpliftManagementController.applyRenewalUplift(null, false);
    } catch (Exception e) {
      // Exception as expected
    }

    Test.stopTest();
  }

  @IsTest
  private static void renewalForecastTest() {
    Contract con = [
      SELECT Id, SBQQ__RenewalForecast__c, Contract_Uplift_Enabled__c
      FROM Contract
      WHERE Account.Name = 'CPQRenewalsUpliftTest_SL Account'
      LIMIT 1
    ];

    try {
      ContractRenewalQueueable_SL renewalQueueable = new ContractRenewalQueueable_SL(con);
      renewalQueueable.execute(null);

      con = [SELECT Id, SBQQ__RenewalForecast__c FROM Contract WHERE Id = :con.Id];
      System.assertEquals(true, con.SBQQ__RenewalForecast__c, 'Renewal forecast queueable is not working');
    } catch (Exception e) {
    }
  }
}