/**
 * @AUTHOR: UIPath
 * @DATE: 10/11/2021
 * @DESCRIPTION: Test class of UltimateParentAccountShare_ET
 */
@isTest
public class UltimateParentAccountShareTest_ET {
  public static testMethod void testUltimateParentAccountMethod() {
    User objUser = new User();
    objUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    objUser.Username = 'test8397341@uiath.com';
    objUser.LastName = 'Test1';
    objUser.Email = 'test8397341@uiath.com';
    objUser.Alias = 't839734';
    objUser.TimeZoneSidKey = 'America/Los_Angeles';
    objUser.LocaleSidKey = 'en_US';
    objUser.EmailEncodingKey = 'UTF-8';
    objUser.LanguageLocaleKey = 'en_US';
    insert objUser;

    Id customerRecTypeId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Customer')
      .getRecordTypeId();
    Account ultimateParentAccount = new Account(
      Industry = 'Engineering',
      BillingCountry = 'United States',
      BillingPostalCode = '012345',
      Name = 'Ultimate Parent Account ',
      Owner_Sync_Status__c = 'Synched',
      Owner_Updated_On__c = System.now(),
      Named_List_Assignment__c = 'AMER',
      OwnerId = objUser.Id,
      Overwrite_Classification__c = true,
      Classification__c = 'KAP',
      RecordTypeId = customerRecTypeId
    );
    insert ultimateParentAccount;

    List<Account> listOfAccount = new List<Account>();
    Account childAccount1 = new Account(
      Industry = 'Engineering',
      BillingCountry = 'United Kingdom',
      BillingPostalCode = '012345',
      ParentId = ultimateParentAccount.Id,
      Name = 'Child Account 1',
      Overwrite_Classification__c = true,
      Classification__c = 'KAP',
      Named_List_Assignment__c = 'AMER',
      RecordTypeId = customerRecTypeId
    );
    listOfAccount.add(childAccount1);
    Account childAccount2 = new Account(
      Industry = 'Engineering',
      BillingCountry = 'United Kingdom',
      BillingPostalCode = '012345',
      Owner_Sync_Status__c = 'Synched',
      Owner_Updated_On__c = System.now(),
      ParentId = ultimateParentAccount.Id,
      Name = 'Child Account 2',
      Overwrite_Classification__c = true,
      Classification__c = 'KAP',
      Named_List_Assignment__c = 'AMER',
      RecordTypeId = customerRecTypeId
    );
    listOfAccount.add(childAccount2);
    insert listOfAccount;

    System.runAs(new User(Id = userinfo.getUserId())) {
      Test.startTest();
      UltimateParentAccountShare_ET batch = new UltimateParentAccountShare_ET();
      // Ultimate Parent Account batch logic will work when Owner Updated on >= Yesterday AND Owner Sync Status = Synched, for this test class we have removed the syched logic from the below query.

      batch.execute(
        null,
        [
          SELECT
            Id,
            OwnerId,
            Owner.Email,
            Is_Domestic_Child__c,
            Ultimate_Parent_Id__c,
            ParentId,
            Owner_Updated_On__c,
            Owner_Sync_Status__c,
            Classification__c
          FROM Account
          WHERE Owner_Updated_On__c >= Yesterday
        ]
      );
      Test.stopTest();
      List<AccountShare> listOfAccountShare = [
        SELECT Id
        FROM AccountShare
        WHERE RowCause = 'Manual' AND LastModifiedDate = TODAY
      ];
      for (Account objAccount : [SELECT Id, KAM_GSI__c, KAM_Email__c FROM Account WHERE Id IN :listOfAccount]) {
        System.assertEquals(
          ultimateParentAccount.OwnerId,
          objAccount.KAM_GSI__c,
          'After Sharing Child Accounts to Ultimate Parent Account, updating KAM_GSI__c field with Ultimate Parent Account Owner Id'
        );
        System.assertEquals(
          objUser.Email,
          objAccount.KAM_Email__c,
          'After Sharing Child Accounts to Ultimate Parent Account, updating KAM_Email__c field with Ultimate Parent Account Owner Email'
        );
      }
      System.assertEquals(
        2,
        listOfAccountShare.size(),
        'All the child account records shared with Ultimate Parent Account Owner Id'
      );
    }
  }
}