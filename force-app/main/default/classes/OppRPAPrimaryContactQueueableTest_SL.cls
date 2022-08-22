@isTest(isParallel=false)
private class OppRPAPrimaryContactQueueableTest_SL {
  @testSetup
  static void setup() {
    Account testAccount = DataFactory_CM.createAccount('Customer', true);
    Contact testContact = DataFactory_CM.createContact(testAccount.Id, true);
    Opportunity opp = DataFactory_SL.createOpportunity(testAccount.Id, false);
    opp.RPA_Primary_Contact__c = testContact.Id;
    opp.Name = 'Test Update';
    insert opp;
    Product2 prod = DataFactory_SL.createProduct(false);
    prod.Product_Version__c = '2016.2';
    insert prod;
    PricebookEntry pbEntry = DataFactory_SL.createStdPricebookEntry(prod.id, 10, true);
    DataFactory_SL.createOpportunityLineItem(pbEntry.id, opp.Id, true);
  }

  @isTest
  private static void setRPAPrimaryContactOnUpdate() {
    Opportunity opp = [
      SELECT Id, StageName, RPA_Primary_Contact__c
      FROM Opportunity
      WHERE Name = 'Test Update'
      LIMIT 1
    ];
    opp.StageName = OpportunityMetadata_SL.CLOSED_WON_PENDING;
    opp.Won_Reasons__c = 'Successful POC';
    update opp;

    OppRPAPrimaryContactQueueable_SL queueable = new OppRPAPrimaryContactQueueable_SL(new List<Opportunity>{ opp });
    queueable.execute(null);

    Test.startTest();
    Contact contact = [SELECT Id, Role__c FROM Contact LIMIT 1];
    System.assertEquals('RPA Primary Contact', contact.Role__c, 'Contact Role is incorrect');
    Test.stopTest();
  }
}