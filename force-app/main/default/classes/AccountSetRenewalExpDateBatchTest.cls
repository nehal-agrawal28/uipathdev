@isTest
private class AccountSetRenewalExpDateBatchTest {
  @testSetup
  static void setup() {
    Account testAccountOne = DataFactory_CM.createAccount('Customer', false);
    testAccountOne.Name = 'First Account';
    insert testAccountOne;

    Account testAccountTwo = DataFactory_CM.createAccount('Customer', false);
    testAccountTwo.Name = 'Second Account';
    insert testAccountTwo;
  }
  
  @isTest
  private static void checkBatch() {
      
      List<Opportunity> opps = new List<Opportunity>();
      
      Account testAccountOne = [SELECT Id, Earliest_Renewal_Expiry_Date__c FROM Account WHERE Name = 'First Account'  LIMIT 1];
      Opportunity oppAccountOne1 = DataFactory_SL.createOpportunity(testAccountOne.Id, false);
      oppAccountOne1.Renewal_Expiry_Date__c = Date.Today().addDays(10);
      oppAccountOne1.StageName = 'Discovery';
      oppAccountOne1.ARR_to_Renew__c = 100;
      opps.add(oppAccountOne1);
        
      Opportunity oppAccountOne2 = DataFactory_SL.createOpportunity(testAccountOne.Id, false);
      oppAccountOne2.Renewal_Expiry_Date__c = Date.Today().addDays(40);
      oppAccountOne2.StageName = 'Discovery';
      oppAccountOne2.ARR_to_Renew__c = 100;
      opps.add(oppAccountOne2);
      
      Opportunity oppAccountOne3 = DataFactory_SL.createOpportunity(testAccountOne.Id, false);
      oppAccountOne3.Renewal_Expiry_Date__c = Date.Today().addDays(-30);
      oppAccountOne3.StageName = 'Discovery';
      oppAccountOne3.ARR_to_Renew__c = 100;
      opps.add(oppAccountOne3);
      
      Opportunity oppAccountOne4 = DataFactory_SL.createOpportunity(testAccountOne.Id, false);
      oppAccountOne4.Renewal_Expiry_Date__c = Date.Today().addDays(5);
      oppAccountOne4.StageName = 'Closed Lost';
      oppAccountOne4.ARR_to_Renew__c = 100;
      opps.add(oppAccountOne4);
      
      
      
      Account testAccountTwo = [SELECT Id, Earliest_Renewal_Expiry_Date__c FROM Account WHERE Name = 'Second Account'  LIMIT 1];
      Opportunity oppAccountTwo1 = DataFactory_SL.createOpportunity(testAccountTwo.Id, false);
      oppAccountTwo1.Renewal_Expiry_Date__c = Date.Today().addDays(-49);
      oppAccountTwo1.StageName = 'Discovery';
      oppAccountTwo1.ARR_to_Renew__c = 100;
      opps.add(oppAccountTwo1);
      
      Opportunity oppAccountTwo2 = DataFactory_SL.createOpportunity(testAccountTwo.Id, false);
      oppAccountTwo2.Renewal_Expiry_Date__c = Date.Today().addDays(56);
      oppAccountTwo2.StageName = 'Discovery';
      oppAccountTwo2.ARR_to_Renew__c = 100;
      opps.add(oppAccountTwo2);
      
      Opportunity oppAccountTwo3 = DataFactory_SL.createOpportunity(testAccountTwo.Id, false);
      oppAccountTwo3.Renewal_Expiry_Date__c = Date.Today().addDays(17);
      oppAccountTwo3.StageName = 'Discovery';
      oppAccountTwo3.ARR_to_Renew__c = 100;
      opps.add(oppAccountTwo3);
      
      Opportunity oppAccountTwo4 = DataFactory_SL.createOpportunity(testAccountTwo.Id, false);
      oppAccountTwo4.Renewal_Expiry_Date__c = Date.Today().addDays(12);
      oppAccountTwo4.StageName = 'Discovery';
      opps.add(oppAccountTwo4);
      
      insert opps;

      List<Account> accToUpdate = new List<Account>();
      testAccountOne.Earliest_Renewal_Expiry_Date__c = null;
      accToUpdate.add(testAccountOne);
      testAccountTwo.Earliest_Renewal_Expiry_Date__c = null;
      accToUpdate.add(testAccountTwo);
      update accToUpdate;
      
      Test.startTest(); 
        AccountSetRenewalExpDateBatch accBatchObject = new AccountSetRenewalExpDateBatch(); 
        Id batchId = Database.executeBatch(accBatchObject);
      Test.stopTest();
      
      List<Account> acctsFinal = [SELECT Id, Name, Earliest_Renewal_Expiry_Date__c FROM Account];
      for(Account acc : acctsFinal) {
          if(acc.Name == 'First Account')
            System.assertEquals(Date.Today().addDays(10), acc.Earliest_Renewal_Expiry_Date__c);
          if(acc.Name == 'Second Account')
            System.assertEquals(Date.Today().addDays(17), acc.Earliest_Renewal_Expiry_Date__c);
      }
  }
  
}