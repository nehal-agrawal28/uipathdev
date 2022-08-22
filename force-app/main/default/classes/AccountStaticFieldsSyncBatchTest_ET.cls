@isTest
public class AccountStaticFieldsSyncBatchTest_ET {
  public static testMethod void accountTriggerTest() {
    Id customerRecTypeId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Customer')
      .getRecordTypeId();
    Account parentAccount = new Account(
      Industry = 'Engineering',
      BillingCountry = 'United States',
      BillingCountryCode = 'US',
      BillingPostalCode = '012345',
      Name = 'Ultimate Parent Account ',
      Owner_Sync_Status__c = 'Synched',
      Owner_Updated_On__c = System.now(),
      Named_List_Assignment__c = 'AMER',
      Overwrite_Classification__c = true,
      Classification__c = 'KAP',
      RecordTypeId = customerRecTypeId
    );
    insert parentAccount;
    Account childAccount1 = new Account(
      Industry = 'Engineering',
      BillingCountry = 'United Kingdom',
      BillingPostalCode = '012345',
      ParentId = parentAccount.Id,
      Name = 'Child Account 1',
      Overwrite_Classification__c = true,
      Classification__c = 'KAP',
      Named_List_Assignment__c = 'AMER',
      RecordTypeId = customerRecTypeId
    );
    insert childAccount1;
    Account childAccount2 = new Account(
      Industry = 'Engineering',
      BillingCountry = 'United States',
      BillingCountryCode = 'US',
      BillingPostalCode = '012645',
      Owner_Sync_Status__c = 'Synched',
      Owner_Updated_On__c = System.now(),
      ParentId = parentAccount.Id,
      Name = 'Test Child Test Account 2',
      Overwrite_Classification__c = true,
      Classification__c = 'KAP',
      Named_List_Assignment__c = 'AMER',
      RecordTypeId = customerRecTypeId
    );
    insert childAccount2;
    Test.startTest();
    AccountStaticFieldsSyncBatch_ET batch = new AccountStaticFieldsSyncBatch_ET();
    batch.execute(
      null,
      [
        SELECT
          Id,
          Sync_Static_Fields__c,
          BillingPostalCode,
          ParentId,
          BillingCountryCode,
          Named_List_Assignment__c,
          AnnualRevenue,
          Ultimate_Parent_Id__c,
          Is_Domestic_Child__c,
          Territory_Postal_Code_Mapping__c,
          BillingStateCode
        FROM Account
        WHERE RecordType.DeveloperName != 'Academic' AND RecordType.DeveloperName != 'Technology_Alliance'
      ]
    );
    Test.stopTest();
    Account childAccount01 = [SELECT Id, Is_Domestic_Child__c FROM Account WHERE Id = :childAccount1.Id];
    Account childAccount02 = [SELECT Id, Is_Domestic_Child__c FROM Account WHERE Id = :childAccount2.Id];
    System.assertEquals(
      false,
      childAccount01.Is_Domestic_Child__c,
      'Is Domestic Child will be set as false becuase parent and child account are not from the same country'
    );
    System.assertEquals(
      true,
      childAccount02.Is_Domestic_Child__c,
      'Is Domestic Child will be set as false becuase parent and child account are from the same country'
    );
  }
}