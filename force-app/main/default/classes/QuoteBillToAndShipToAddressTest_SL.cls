@IsTest
public with sharing class QuoteBillToAndShipToAddressTest_SL {
  @TestSetup
  static void makeData() {
    SBQQ.TriggerControl.disable();
    List<Account> customerAccount1 = DataFactory_CM.createAccounts(AccountMetadata.customerRecordType, 1, false);
    List<Account> customerAccount2 = DataFactory_CM.createAccounts(AccountMetadata.customerRecordType, 1, false);
    customerAccount2.get(0).Name = 'Testing';
    insert new List<Account>{ customerAccount1.get(0), customerAccount2.get(0) };

    Opportunity opp1 = DataFactory_SL.createOpportunity(customerAccount1.get(0).Id, false);
    insert new List<Opportunity>{ opp1 };

    List<Address__c> address = DataFactory_CM.createAddress(1, customerAccount1.get(0).Id, false);
    address.get(0).Primary_Billing__c = true;
    address.get(0).Primary_Shipping__c = true;
    address.get(0).NS_Address_Internal_ID__c = '677612';
    insert address;
  }

  @IsTest
  static void testaddBillToAndShipToAddress() {
    Account account = [SELECT Id FROM Account WHERE RecordTypeId = :AccountMetadata.customerRecordType LIMIT 1];
    Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :account.Id LIMIT 1];
    SBQQ__Quote__c quote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, true);

    fflib_SObjectDomain.Test.Database.onInsert(new List<SBQQ__Quote__c>{ quote });
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    SBQQ__Quote__c fetchUpdatedQuote1 = [SELECT Id, Ship_To_Address__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
    System.assertNotEquals(fetchUpdatedQuote1.Ship_To_Address__c, null);

    Account account2 = [SELECT Id FROM Account WHERE Name = 'Testing' LIMIT 1];

    quote.Bill_To_Account__c = account2.Id;
    fflib_SObjectDomain.Test.Database.onInsert(new List<SBQQ__Quote__c>{ quote });
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    SBQQ__Quote__c oldQuote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    oldQuote.Bill_To_Account__c = account.Id;
    oldQuote.Id = quote.Id;

    SBQQ__Quote__c updateQuote = DataFactory_SL.createCPQQuote(account.Id, opp.Id, false);
    updateQuote.Bill_To_Account__c = account2.Id;
    updateQuote.Id = quote.Id;

    fflib_SObjectDomain.Test.Database.onUpdate(
      new List<SBQQ__Quote__c>{ updateQuote },
      new Map<Id, SObject>{ oldQuote.Id => oldQuote }
    );
    fflib_SObjectDomain.triggerHandler(Quotes_SL.class);

    SBQQ__Quote__c fetchUpdatedQuote2 = [SELECT Id, Ship_To_Address__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
    System.assertNotEquals(fetchUpdatedQuote2.Ship_To_Address__c, null);
  }
}