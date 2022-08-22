@IsTest
private class ContractOrderFunctionTest_SL {
  @IsTest
  static void onUpdate_setOriginalOrderId() {
    Id accountId = fflib_IDGenerator.generate(Account.SObjectType);
    Id oppId = fflib_IDGenerator.generate(Opportunity.SObjectType);
    Id orderId = fflib_IDGenerator.generate(Order.SObjectType);
    Id contractId = fflib_IDGenerator.generate(Contract.SObjectType);

    Contract existingRecord = new Contract(
      Id = contractId,
      AccountId = accountId,
      SBQQ__Opportunity__c = oppId,
      StartDate = Date.today(),
      ContractTerm = 12,
      SBQQ__Order__c = orderId,
      Original_OrderID__c = null
    );

    Contract newRecord = new Contract(
      Id = contractId,
      AccountId = accountId,
      SBQQ__Opportunity__c = oppId,
      StartDate = Date.today(),
      ContractTerm = 12,
      SBQQ__Order__c = orderId,
      Original_OrderID__c = null,
      SBQQ__RenewalForecast__c = false
    );

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<Contract>{ newRecord },
      new Map<Id, SObject>{ contractId => existingRecord }
    );

    fflib_SObjectDomain.triggerHandler(Contracts_SL.class);

    System.assertEquals(orderId, newRecord.Original_OrderID__c, 'Original Order Id not set on update');
  }
}