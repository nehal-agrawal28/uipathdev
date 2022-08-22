@isTest
public class PartnerInvolvementsServiceTest_ET {
  @TestSetup
  static void setup() {
    Id partnerRecordTpeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getrecordTypeId();
    Id customerRecordTypeId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getrecordTypeId();
    Id partnerTerritoryTypeId = [
      SELECT Id
      FROM Territory2Type
      WHERE MasterLabel = :ETMConstant.PARTNER_MANAGEMENT
      LIMIT 1
    ]
    .Id;

    List<Account> listOfAccount = new List<Account>();
    List<ObjectTerritory2Association> listOfObjectTerrAss = new List<ObjectTerritory2Association>();
    Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');
    Territory2 partnerTerritory1 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Partner Territory 1', false);
    partnerTerritory1.Sales_Territory__c = false;
    partnerTerritory1.Territory2TypeId = partnerTerritoryTypeId;
    insert partnerTerritory1;

    Territory2 partnerTerritory2 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Partner Territory 2', false);
    partnerTerritory2.Sales_Territory__c = false;
    partnerTerritory2.Territory2TypeId = partnerTerritoryTypeId;
    insert partnerTerritory2;

    User objUser = new User(
      ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator']
      .Id,
      Username = 'test839734@uiath.com',
      LastName = 'Test',
      Email = 'test839734@uiath.com',
      Alias = 't839734',
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert objUser;

    System.runAs(objUser) {
      Account partnerAccount1 = new Account(
        Name = 'Test Partner Account 01',
        Industry = 'Engineering',
        BillingCountry = 'United States',
        BillingPostalCode = '012345',
        Partner_Named_List_Assignment__c = 'Test Partner Territory 1',
        RecordTypeId = partnerRecordTpeId
      );
      listOfAccount.add(partnerAccount1);
      Account partnerAccount2 = new Account(
        Name = 'Test Partner Account 02',
        Industry = 'Engineering',
        BillingCountry = 'United States',
        BillingPostalCode = '012345',
        Partner_Named_List_Assignment__c = 'Test Partner Territory 2',
        RecordTypeId = partnerRecordTpeId
      );
      listOfAccount.add(partnerAccount2);
      Account customerAccount = new Account(
        Name = 'Test Customer Account',
        Industry = 'Engineering',
        BillingCountry = 'United States',
        BillingPostalCode = '012345',
        RecordTypeId = customerRecordTypeId
      );
      listOfAccount.add(customerAccount);
      insert listOfAccount;

      listOfObjectTerrAss.add(
        new ObjectTerritory2Association(
          ObjectId = listOfAccount[0].Id,
          Territory2Id = partnerTerritory1.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      listOfObjectTerrAss.add(
        new ObjectTerritory2Association(
          ObjectId = listOfAccount[1].Id,
          Territory2Id = partnerTerritory2.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert listOfObjectTerrAss;
      Opportunity opp = new Opportunity(
        Accountid = listOfAccount[2].Id,
        StageName = 'Discovery',
        CloseDate = System.today(),
        Name = 'Test Customer Opportunity',
        Type = 'Upsell',
        Deal_Type__c = 'BPO',
        CurrencyIsoCode = 'USD',
        Led_by__c = 'Direct Led',
        LeadSource = 'Partner'
      );
      insert opp;

      Test.startTest();
      Partner_Involvement__c objPartnerInvolvment = new Partner_Involvement__c(
        PartnerOpp_Name__c = opp.Id,
        Partner_Account_Name__c = listOfAccount[1].Id,
        Partner_Sales_Role__c = 'Influence (No Financial Comp from UiPath)',
        Partner_Sales_Contribution__c = 'Led',
        Partner_Delivery_Role__c = 'Primary Implementation',
        Partner_Technical_Contribution__c = 'Led (Primary Implementation)',
        Influence_Approval_Status__c = 'Approved'
      );
      insert objPartnerInvolvment;
      Test.stopTest();
    }
  }

  @isTest
  public static void testUpdatePartnerInvolvement() {
    User objUser = [SELECT Id FROM User WHERE Email = 'test839734@uiath.com' LIMIT 1];
    Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
    Id partnerAccount1Id = [SELECT Id FROM Account WHERE Name = 'Test Partner Account 01' LIMIT 1].Id;
    Id partnerAccount2Id = [SELECT Id FROM Account WHERE Name = 'Test Partner Account 02' LIMIT 1].Id;
    System.runAs(objUser) {
      Test.startTest();
      Partner_Involvement__c objPartnerInvolvment = new Partner_Involvement__c(
        PartnerOpp_Name__c = oppId,
        Partner_Account_Name__c = partnerAccount1Id,
        Partner_Sales_Role__c = 'Influence (No Financial Comp from UiPath)',
        Partner_Sales_Contribution__c = 'Led',
        Partner_Delivery_Role__c = 'Primary Implementation',
        Partner_Technical_Contribution__c = 'Led (Primary Implementation)',
        Influence_Approval_Status__c = 'Approved'
      );
      insert objPartnerInvolvment;
      objPartnerInvolvment.Partner_Account_Name__c = partnerAccount2Id;
      update objPartnerInvolvment;
      Test.stopTest();
      Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :oppId LIMIT 1];
      List<ObjectTerritory2Association> customerAccountOTAs = [
        SELECT Id, Territory2Id, Territory2.Name
        FROM ObjectTerritory2Association
        WHERE ObjectId = :objOpp.AccountId
      ];
      System.assertEquals(
        'Test Partner Territory 2',
        customerAccountOTAs[0].Territory2.Name,
        'Test Partner Account 02 territory assigned to the customer Account'
      );
      System.assertEquals(1, customerAccountOTAs.size());
    }
  }

  @isTest
  public static void testDeletePartnerInvolvment() {
    User objUser = [SELECT Id FROM User WHERE Email = 'test839734@uiath.com' LIMIT 1];
    Id partnerInvolvmentId = [SELECT Id FROM Partner_Involvement__c LIMIT 1].Id;
    Opportunity objOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
    System.runAs(objUser) {
      Test.startTest();
      delete [SELECT Id FROM Partner_Involvement__c WHERE Id = :partnerInvolvmentId LIMIT 1];
      Test.stopTest();
      List<ObjectTerritory2Association> customerAccountOTAs = [
        SELECT Id, Territory2Id, Territory2.Name
        FROM ObjectTerritory2Association
        WHERE ObjectId = :objOpp.AccountId
      ];
      System.assertEquals(
        0,
        customerAccountOTAs.size(),
        'partner teritories deleted from customer account when delete Partner Involvement record'
      );
    }
  }
}