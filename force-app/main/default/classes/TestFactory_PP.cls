@IsTest(isParallel=true)
public without sharing class TestFactory_PP {
  public static final String EMAIL_SUFFIX = '@example.com';
  public static final String COMMUNITY_USER_PROFILE = 'Global Partner Portal Login User';
  public static final String SYSTEM_ADMIN_PROFILE = 'System Administrator';
  public static final String SUFFIX = Datetime.now().format('yyMMdd') + 'test';

  public static void init() {
    User systemContextUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    User systemAdminUser;

    System.runAs(systemContextUser) {
      String roleName = 'role' + SUFFIX;
      UserRole role = new UserRole(DeveloperName = roleName, Name = roleName);
      insert role;

      systemAdminUser = buildUser('systemadminuser' + SUFFIX, SYSTEM_ADMIN_PROFILE, role.Id, null);
      insert systemAdminUser;
    }

    Account dealRegistrationPartnerAccount = buildPartnerAccount(
      System.Label.Deal_Reg_Partner_Account_Name,
      systemAdminUser.Id,
      null
    );
    insert dealRegistrationPartnerAccount;

    Account distributorAccount = buildPartnerAccount('distributoraccount' + SUFFIX, systemAdminUser.Id, true);
    insert distributorAccount;
    distributorAccount.IsPartner = true;
    update distributorAccount;

    Account resellerAccount = buildPartnerAccount('reselleraccount' + SUFFIX, systemAdminUser.Id, false);
    insert resellerAccount;
    resellerAccount.IsPartner = true;
    update resellerAccount;

    AccountRelationship distributorToReseller = new AccountRelationship(
      Name = 'Distributor to Reseller',
      AccountFromId = distributorAccount.Id,
      AccountToId = resellerAccount.Id,
      Type = 'Distributor'
    );
    insert distributorToReseller;

    AccountRelationship resellerToDistributor = new AccountRelationship(
      Name = 'Reseller to Distributor',
      AccountFromId = resellerAccount.Id,
      AccountToId = distributorAccount.Id,
      Type = 'VAR/Reseller'
    );
    insert resellerToDistributor;
  }

  public static void initPortalUsers() {
    User systemAdminUser = [SELECT Id FROM User WHERE Name LIKE 'systemadminuser%' LIMIT 1];
    Account distributorAccount = [SELECT Id FROM Account WHERE Name LIKE 'distributoraccount%' LIMIT 1];
    Account resellerAccount = [SELECT Id FROM Account WHERE Name LIKE 'reselleraccount%' LIMIT 1];

    Contact distributorContact = buildPartnerContact(
      'distributorcontact' + SUFFIX,
      distributorAccount.Id,
      'distributor.contact@testemail.com'
    );
    insert distributorContact;

    Contact resellerContact = buildPartnerContact(
      'resellercontact' + SUFFIX,
      resellerAccount.Id,
      'reseller.contact@testemail.com'
    );
    insert resellerContact;

    System.runAs(systemAdminUser) {
      insert buildUser('distributoruser' + SUFFIX, COMMUNITY_USER_PROFILE, null, distributorContact.Id);
      insert buildUser('reselleruser' + SUFFIX, COMMUNITY_USER_PROFILE, null, resellerContact.Id);
    }
  }

  public static Account buildPartnerAccount(String name, Id ownerId, Boolean isDistributor) {
    Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner').getRecordTypeId();

    Account account = new Account(
      Name = name,
      OwnerId = ownerId,
      RecordTypeId = recordTypeId,
      BillingCountry = 'United States',
      Country__c = 'United States',
      Industry = 'Technology'
    );

    if (isDistributor != null) {
      account.Business_Partner_Type__c = isDistributor ? 'Distributor' : 'VAR';
      account.Type = 'Business Partner';
    }

    return account;
  }

  public static Contact buildPartnerContact(String name, Id accountId, String emailAddress) {
    return new Contact(
      FirstName = name,
      LastName = name,
      AccountId = accountId,
      Email = emailAddress,
      Department__c = 'IT'
    );
  }

  public static User buildUser(String userFirstName, String profileName, Id roleId, Id contactId) {
    User user = new User();
    user.Username = userFirstName + EMAIL_SUFFIX;
    user.Email = userFirstName + EMAIL_SUFFIX;
    user.ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1].Id;
    user.FirstName = userFirstName;
    user.LastName = 'testuser';
    user.Alias = 'testuser';
    user.EmailEncodingKey = 'UTF-8';
    user.LanguageLocaleKey = 'en_US';
    user.LocaleSidKey = 'en_US';
    user.TimeZoneSidKey = 'GMT';
    user.Country = 'Belgium';

    if (String.IsNotBlank(roleId)) {
      user.UserRoleId = roleId;
    }

    if (String.IsNotBlank(contactId)) {
      user.ContactId = contactId;
    }

    return user;
  }

  public static DealRegistration__c buildDealRegistration(
    User partnerUser,
    Id distributorAccountId,
    Id resellerAccountId,
    Id priceBookId,
    Boolean isBpo,
    Boolean isSubmittedRecordType
  ) {
    String recordTypeDeveloperName = isSubmittedRecordType ? 'SubmittedDealRegistration' : 'DraftDealRegistration';

    Id recordTypeId = Schema.SObjectType.DealRegistration__c
      .getRecordTypeInfosByDeveloperName()
      .get(recordTypeDeveloperName)
      .getRecordTypeId();

    DealRegistration__c record = new DealRegistration__c(
      BPOOpportunity__c = isBpo,
      Account__c = partnerUser.Contact_Account_Id__c,
      OwnerId = partnerUser.Id,
      RecordTypeId = recordTypeId,
      CloseDate__c = Date.today(),
      City__c = 'Frankfurt',
      Competition__c = 'Automation Anywhere',
      Country__c = 'Germany',
      CurrencyIsoCode = 'USD',
      DealRegNotesComments__c = 'Notes',
      DealRegistrationAmount__c = null,
      Name = 'Test Deal Reg',
      DealType__c = 'Resale',
      EndCustomerAccountName__c = 'UiPath',
      EndCustomerWebsite__c = 'UiPath.com',
      PartnerCompanySalesEmail__c = 'Test@UiPath.com',
      PartnerCompanySalesPhone__c = '0178945244',
      PartnerCompanySalesRep__c = 'Test Sales Rep',
      PartnerLeadSource__c = 'Advertisement'
    );

    if (String.isNotBlank(distributorAccountId)) {
      record.Distributor__c = distributorAccountId;
    }

    if (String.isNotBlank(resellerAccountId)) {
      record.Tier2Partner__c = resellerAccountId;
    }

    if (String.isNotBlank(priceBookId)) {
      record.PriceBook__c = priceBookId;
    }

    return record;
  }

  public static Opportunity buildDealRegistrationOpportunity(
    DealRegistration__c dealRegistration,
    Id partnerAccountId
  ) {
    Account dealRegistrationPartnerAccount = [
      SELECT Id, OwnerId
      FROM Account
      WHERE Name = :System.Label.Deal_Reg_Partner_Account_Name
      LIMIT 1
    ];

    Id dealRegistrationRecordTypeId = Schema.SObjectType.Opportunity
      .getRecordTypeInfosByDeveloperName()
      .get('Deal_Registration')
      .getRecordTypeId();

    Opportunity record = new Opportunity(
      AccountId = dealRegistrationPartnerAccount.Id,
      Account_City__c = dealRegistration.City__c,
      Account_Country__c = dealRegistration.Country__c,
      Account_Name__c = dealRegistration.EndCustomerAccountName__c,
      Amount = dealRegistration.DealRegistrationAmount__c,
      CloseDate = dealRegistration.CloseDate__c,
      Competition__c = dealRegistration.Competition__c,
      CurrencyIsoCode = dealRegistration.CurrencyIsoCode,
      DealRegEndCustomerWebsite__c = dealRegistration.EndCustomerWebsite__c,
      Deal_Reg_Notes_Comments__c = dealRegistration.DealRegNotesComments__c,
      Deal_Reg_Partner_SFDC_Id__c = partnerAccountId,
      Deal_Registration_System__c = 'Community',
      Deal_Type__c = dealRegistration.DealType__c,
      LeadSource = 'Partner',
      Partner_Lead_Source__c = dealRegistration.PartnerLeadSource__c,
      Name = dealRegistration.Name,
      OwnerId = dealRegistrationPartnerAccount.OwnerId,
      Partner_Sales_Email__c = dealRegistration.PartnerCompanySalesEmail__c,
      Partner_Sales_Phone__c = dealRegistration.PartnerCompanySalesPhone__c,
      Partner_Sales_Rep__c = dealRegistration.PartnerCompanySalesRep__c,
      Pricebook2Id = dealRegistration.PriceBook__c,
      Probability = 0,
      RecordTypeId = dealRegistrationRecordTypeId,
      StageName = 'Deal Registration'
    );

    return record;
  }
}