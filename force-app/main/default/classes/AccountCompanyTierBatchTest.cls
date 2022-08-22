@isTest
public class AccountCompanyTierBatchTest {
    /*private static final string AccountEMEA = 'Test Account EMEA';
    private static final string AccountAMER = 'Test Account AMER';
    private static final string AccountAPAC = 'Test Account APAC';
    private static final string AccountIndia = 'Test Account India';
    private static final string AccountJapan = 'Test Account Japan';
    private static final string NewZealand = 'New Zealand';
  
  @isTest
    public static void setUpCompanyTierInsert1Test()
    {  
 
    Id prospectRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();

    Account accEMEA = new Account(
      Name = AccountEMEA,
      RecordTypeId = prospectRT,
      Country__c = 'Romania',
      Geo__c = 'EMEA',
      BillingCountry = 'Romania',
      Classification__c = 'SMB',
      AnnualRevenue = 100000,
      Industry = 'Energy',
      Overwrite_Classification__c = true,
      Top_Account__c = true
    );
    insert accEMEA;
    Test.startTest();
        AccountCompanyTierBatch b = new AccountCompanyTierBatch();
        Database.executeBatch(b);
    Test.stopTest();
    
    Account insertedAcc = [SELECT Id, Company_Tier__c FROM Account WHERE Id = :accEMEA.Id];

    System.assertEquals('A', insertedAcc.Company_Tier__c);
  }

  @isTest
  private static void setUpCompanyTierInsert2Test() {
    Id prospectRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();

    Account enterpriseParentAcc = new Account(
      Name = 'Parent Account 1',
      RecordTypeId = prospectRT,
      Country__c = 'France',
      Industry = 'Energy',
      Classification__c = 'SMB',
      Overwrite_Classification__c = true,
      Top_Account__c = true
    );
    insert enterpriseParentAcc;

    Account velocityParentAcc = new Account(
      Name = 'Parent Account 2',
      RecordTypeId = prospectRT,
      Country__c = 'Italy',
      Industry = 'Construction',
      Classification__c = 'Velocity',
      Overwrite_Classification__c = true
    );
    insert velocityParentAcc;

    Account sMBParentAcc = new Account(
      Name = 'Parent Account 3',
      RecordTypeId = prospectRT,
      Country__c = 'Germany',
      Industry = 'Communications',
      Classification__c = 'SMB',
      Overwrite_Classification__c = true
    );
    insert sMBParentAcc;

    List<Account> accToInsert = new List<Account>();

    Account accEMEAt1 = new Account(
      Name = AccountEMEA,
      RecordTypeId = prospectRT,
      ParentId = sMBParentAcc.Id,
      Country__c = 'Romania',
      Geo__c = 'EMEA',
      Classification__c = 'SMB',
      Industry = 'Energy',
      Overwrite_Classification__c = true
    );
    accToInsert.add(accEMEAt1);

    Account accAMERt1 = new Account(
      Name = AccountAMER,
      RecordTypeId = prospectRT,
      ParentId = velocityParentAcc.Id,
      Country__c = 'Canada',
      Geo__c = 'AMER',
      BillingCountry = 'Canada',
      Classification__c = 'Enterprise',
      AnnualRevenue = 300000000.00,
      Industry = 'Energy',
      Overwrite_Classification__c = true,
      Region_Specific__c = 'Velocity Tier 1'
    );
    accToInsert.add(accAMERt1);

    Account accIndiat1 = new Account(
      Name = AccountIndia,
      RecordTypeId = prospectRT,
      ParentId = velocityParentAcc.Id,
      Country__c = 'India',
      Geo__c = 'India',
      BillingCountry = 'India',
      Classification__c = 'Commercial',
      Region_Specific__c = 'India Business - Top Strategic Accounts',
      AnnualRevenue = 300000000.00,
      Industry = 'Energy',
      Overwrite_Classification__c = true
    );
    accToInsert.add(accIndiat1);

    Account accJapant1 = new Account(
      Name = AccountJapan,
      RecordTypeId = prospectRT,
      Country__c = 'Japan',
      Geo__c = 'Japan',
      BillingCountry = 'Japan',
      Classification__c = 'Commercial',
      AnnualRevenue = 100000.00,
      Industry = 'Energy',
      Overwrite_Classification__c = true,
      ShippingCountry = 'Japan',
      ShippingCountryCode = 'JP',
      NumberOfEmployees = 100,
      ShippingState = 'Aichi',
      ShippingStateCode = 'AI'
      
    );
    accToInsert.add(accJapant1);

    Account accAPACt1 = new Account(
      Name = AccountAPAC,
      RecordTypeId = prospectRT,
      ParentId = sMBParentAcc.Id,
      Country__c = NewZealand,
      Geo__c = 'APAC',
      BillingCountry = NewZealand,
      Classification__c = 'Commercial',
      AnnualRevenue = 30000.00,
      Industry = 'Energy',
      Overwrite_Classification__c = true
      
    );
    accToInsert.add(accAPACt1);

    insert accToInsert;

    Test.startTest();
        AccountCompanyTierBatch b = new AccountCompanyTierBatch();
        Database.executeBatch(b);
    Test.stopTest();

    List<Account> allAccs = [SELECT Id, Classification__c,Ultimate_Parent_Classification__c, Name, Company_Tier__c FROM Account];
    for (Account acc : allAccs) {
      System.debug('Name ======> '+ acc.Name);
      System.debug('Classification__c ======> '+ acc.Classification__c);
      System.debug('Ultimate_Parent_Classification__c ======> '+ acc.Ultimate_Parent_Classification__c);
      System.debug('Company_Tier__c ======> '+ acc.Company_Tier__c );
      if (acc.Name == AccountAMER) {
        System.assertEquals('B', acc.Company_Tier__c);
      }
      if (acc.Name == AccountIndia) {
        System.assertEquals('B', acc.Company_Tier__c);
      }
      if (acc.Name == AccountAPAC) {
        System.assertEquals('C', acc.Company_Tier__c);
      }
      if (acc.Name == AccountEMEA) {
        System.assertEquals('C', acc.Company_Tier__c);
      }
      if (acc.Name == AccountJapan) {
        System.assertEquals('B', acc.Company_Tier__c);
      }
    }
  }*/

  
}