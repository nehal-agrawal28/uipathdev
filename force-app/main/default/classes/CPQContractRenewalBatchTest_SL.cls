@isTest
public with sharing class CPQContractRenewalBatchTest_SL {
  static void dataSetup() {
    SBQQ.TriggerControl.disable();
    //Create accounts
    fflib_SObjectDomain.getTriggerEvent(Accounts_SL.class).disableAll();
    Account acc1 = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
    Account acc2 = DataFactory_CM.createAccount(Constants.ACCOUNT_RECORD_TYPE_1, true);
    fflib_SObjectDomain.getTriggerEvent(Accounts_SL.class).enableAll();

    //Create contracts
    fflib_SObjectDomain.getTriggerEvent(Contracts_SL.class).disableAll();
    Contract con1 = DataFactory_SL.createContract(acc1.Id, true);
    Contract con2 = DataFactory_SL.createContract(acc1.Id, true);
    Contract con4 = DataFactory_SL.createContract(acc2.Id, true);

    List<Contract> cons = [SELECT Id FROM Contract];
    for (Contract con : cons) {
      con.Status = Constants.ACTIVATED_ORDER_STATUS;
      con.SBQQ__RenewalForecast__c = true;
    }
    update cons;
    fflib_SObjectDomain.getTriggerEvent(Contracts_SL.class).enableAll();

    //Create renewal opps

    Opportunity opp1 = DataFactory_SL.createOpportunity(acc1.Id, false);
    opp1.SBQQ__RenewedContract__c = con1.Id;
    opp1.Type = Constants_SL.QUOTE_TYPE_RENEWAL;
    opp1.StageName = Constants.OPPORTUNITY_STAGE_MERGED;

    Opportunity opp2 = DataFactory_SL.createOpportunity(acc1.Id, false);
    opp2.SBQQ__RenewedContract__c = con2.Id;
    opp2.Type = Constants_SL.QUOTE_TYPE_RENEWAL;

    Opportunity opp4 = DataFactory_SL.createOpportunity(acc2.Id, false);
    opp4.SBQQ__RenewedContract__c = con4.Id;
    opp4.Type = Constants_SL.QUOTE_TYPE_RENEWAL;

    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).disableAll();
    insert new List<Opportunity>{ opp1, opp2, opp4 };
    fflib_SObjectDomain.getTriggerEvent(Opportunities_SL.class).enableAll();

    fflib_SObjectDomain.getTriggerEvent(Contracts_SL.class).disableAll();
    con4.SBQQ__RenewalOpportunity__c = opp4.Id;
    update con4;
    fflib_SObjectDomain.getTriggerEvent(Contracts_SL.class).enableAll();

    Map<Id, Contract> conById = new Map<Id, Contract>(new List<Contract>{ con1, con2 });
    for (Contract con : [SELECT Id, SBQQ__RenewalOpportunity__c FROM Contract WHERE Id IN :conById.keySet()]) {
      System.assertEquals(null, con.SBQQ__RenewalOpportunity__c, 'Contracts should have no renewal opps at this point');
    }
    SBQQ.TriggerControl.enable();
  }

  //Integration
  @isTest
  static void itShouldUpdateTheContractsRenewalOpportunities() {
    //GIVEN
    dataSetup();
    Map<Id, Contract> scopeContracts = new Map<Id, Contract>(
      [SELECT Id, SBQQ__RenewalOpportunity__c FROM Contract WHERE SBQQ__RenewalOpportunity__c = NULL]
    );

    //WHEN
    Test.startTest();
    CPQContractRenewalBatch_SL renewalBatch = new CPQContractRenewalBatch_SL();
    Database.executeBatch(renewalBatch, 3);
    Test.stopTest();

    //THEN
    List<Contract> updatedContracts = [
      SELECT Id, SBQQ__RenewalOpportunity__c
      FROM Contract
      WHERE Id IN :scopeContracts.keySet()
    ];

    for (Contract con : updatedContracts) {
      System.assertNotEquals(null, con.SBQQ__RenewalOpportunity__c, 'Renewal Opportunity should be populated');
    }
  }

  @isTest
  static void itShouldUpdateTheContractsRenewalOpportunitiesUsingRetryLogic() {
    //GIVEN
    dataSetup();
    Map<Id, Contract> scopeContracts = new Map<Id, Contract>(
      [SELECT Id, SBQQ__RenewalOpportunity__c FROM Contract WHERE SBQQ__RenewalOpportunity__c = NULL]
    );

    //WHEN
    Test.startTest();
    CPQContractRenewalBatch_SL renewalBatch = new CPQContractRenewalBatch_SL(scopeContracts.keySet(), 1);
    Database.executeBatch(renewalBatch, 3);
    Test.stopTest();

    //THEN
    List<Contract> updatedContracts = [
      SELECT Id, SBQQ__RenewalOpportunity__c
      FROM Contract
      WHERE Id IN :scopeContracts.keySet()
    ];

    for (Contract con : updatedContracts) {
      System.assertNotEquals(null, con.SBQQ__RenewalOpportunity__c, 'Renewal Opportunity should be populated');
    }
  }

  @isTest
  static void itShouldUpdateTheContractsRenewalForecast() {
    //GIVEN
    dataSetup();
    Map<Id, Contract> scopeContracts = new Map<Id, Contract>(
      [SELECT Id, SBQQ__RenewalForecast__c FROM Contract WHERE SBQQ__RenewalOpportunity__c = NULL]
    );

    //WHEN
    SBQQ.TriggerControl.disable();
    CPQContractRenewalBatch_SL.RenewalForecaster renewalForecaster = new CPQContractRenewalBatch_SL.RenewalForecaster(
      scopeContracts.keySet()
    );
    renewalForecaster.work();
    SBQQ.TriggerControl.enable();

    //THEN
    List<Contract> updatedContracts = [
      SELECT Id, SBQQ__RenewalForecast__c
      FROM Contract
      WHERE Id IN :scopeContracts.keySet()
    ];
    for (Contract con : updatedContracts) {
      System.assertEquals(true, con.SBQQ__RenewalForecast__c, 'Renewal Forecast should be true');
    }
  }
}