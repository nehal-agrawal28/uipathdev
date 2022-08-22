@isTest
public class OpportunityCompensationServiceTest_ET {
  static void setupData() {
    Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
    List<User> userList = new List<User>();

    for (Integer i = 1; i < 10; i++) {
      User objUser = new User();
      objUser.ProfileId = systemAdminProfileId;
      objUser.Username = 'test839734@' + i + 'uiath.com';
      objUser.LastName = 'Test';
      objUser.Email = 'test839734@uiath.com';
      objUser.Alias = 't839734';
      objUser.TimeZoneSidKey = 'America/Los_Angeles';
      objUser.LocaleSidKey = 'en_US';
      objUser.EmailEncodingKey = 'UTF-8';
      objUser.LanguageLocaleKey = 'en_US';
      userList.add(objUser);
    }
    insert userList;

    List<Default_Compensation__mdt> defComp = [
      SELECT MasterLabel, Role_In_Territory__c, Default_Percentage__c, Status__c
      FROM Default_Compensation__mdt
    ];

    System.runAs(new User(Id = userinfo.getuserId())) {
      Territory2 regionTerr = TestFactory_ET.initTerritory('Geo', 'Area', 'Region');
      List<Territory2> updatedTerrType = new List<Territory2>();
      Territory2Type KAPTerrType = [
        SELECT Id, DeveloperName
        FROM Territory2Type
        WHERE MasterLabel = :ETMConstant.KEY_ACCOUNTS_PROGRAM
      ];
      Territory2Type PartnerTerrType = [
        SELECT Id, DeveloperName
        FROM Territory2Type
        WHERE MasterLabel = :ETMConstant.PARTNER_MANAGEMENT
      ];
      List<Territory2> salesTerr = new List<Territory2>();
      Territory2 terr1 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 1', false);
      Territory2 terr2 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 2', false);
      Territory2 terr3 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 3', false);
      Territory2 terr4 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 4', false);
      Territory2 terr5 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 5', false);
      Territory2 terr6 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 6', false);
      Territory2 terr7 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 7', false);
      Territory2 terr8 = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 8', false);

      terr4.Territory2TypeId = KAPTerrType.Id;
      terr5.Territory2TypeId = PartnerTerrType.Id;
      terr5.Sales_Territory__c = false;
      terr6.Territory2TypeId = PartnerTerrType.Id;
      terr1.ParentTerritory2Id = regionTerr.Id;
      terr2.ParentTerritory2Id = regionTerr.Id;
      terr3.ParentTerritory2Id = regionTerr.Id;
      terr4.ParentTerritory2Id = regionTerr.Id;
      terr5.ParentTerritory2Id = regionTerr.Id;
      terr6.ParentTerritory2Id = regionTerr.Id;
      terr7.ParentTerritory2Id = regionTerr.Id;
      terr8.ParentTerritory2Id = regionTerr.Id;

      salesTerr.add(terr1);
      salesTerr.add(terr2);
      salesTerr.add(terr3);
      salesTerr.add(terr4);
      salesTerr.add(terr5);
      salesTerr.add(terr6);
      salesTerr.add(terr7);
      salesTerr.add(terr8);
      insert salesTerr;

      List<UserTerritory2Association> userAssList = new List<UserTerritory2Association>();

      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = terr1.Id,
          UserId = userList[0].Id,
          RoleInTerritory2 = ETMConstant.INTERIM_ACCOUNT_MANAGER
        )
      );
      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = terr2.Id,
          UserId = userList[0].Id,
          RoleInTerritory2 = ETMConstant.PRIMARY_ACCOUNT_MANAGER
        )
      );
      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = terr3.Id,
          UserId = userList[1].Id,
          RoleInTerritory2 = ETMConstant.PRIMARY_ACCOUNT_MANAGER
        )
      );
      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = terr4.Id,
          UserId = userList[2].Id,
          RoleInTerritory2 = ETMConstant.PRIMARY_ACCOUNT_MANAGER
        )
      );
      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = terr5.Id,
          UserId = userList[3].Id,
          RoleInTerritory2 = ETMConstant.PRIMARY_ACCOUNT_MANAGER
        )
      );
      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = terr5.Id,
          UserId = userList[4].Id,
          RoleInTerritory2 = ETMConstant.GLOBAL_GSI_ALLI_PART_MANAGER
        )
      );

      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = terr7.Id,
          UserId = userList[7].Id,
          RoleInTerritory2 = ETMConstant.PRIMARY_ACCOUNT_MANAGER
        )
      );
      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = terr6.Id,
          UserId = userList[5].Id,
          RoleInTerritory2 = ETMConstant.GSI_PARTNER_MANAGER
        )
      );
      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = terr6.Id,
          UserId = userList[6].Id,
          RoleInTerritory2 = ETMConstant.SEC_GSI_PARTNER_MANAGER
        )
      );
      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = terr8.Id,
          UserId = userList[8].Id,
          RoleInTerritory2 = ETMConstant.REGION_PARTNER_MANAGER
        )
      );
      //TestFactory_ET.createUserTerritoryAssociation(terr4.Id, userList[2].Id, ETMConstant.PRIMARY_ACCOUNT_MANAGER);
      insert userAssList;
    }
  }

  public static testMethod void opportunityOwnerSyncWithPAM() {
    setupdata();
    Territory2 terr = TestFactory_ET.getTerritoryId('Test Sales Territory 3');
    Territory2 accterr = TestFactory_ET.getTerritoryId('Test Sales Territory 2');
    Territory2 parrterr = TestFactory_ET.getTerritoryId('Test Sales Territory 4');

    Id customerRecTypeId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Partner_Prospect')
      .getRecordTypeId();

    List<Account> accountList = TestFactory_ET.createAccounts(2, 'Customer', 'Test Sales Territory 2', false);
    accountList[0].Named_List_Assignment__c = parrterr.Name;
    accountList[0].Overwrite_Classification__c = true;
    accountList[0].Classification__c = 'KAP-GSI';
    accountList[0].RecordTypeId = customerRecTypeId;
    insert accountList[0];

    accountList[1].parentId = accountList[0].Id;
    accountList[1].Name = 'Child Account';
    insert accountList[1];

    update accountList;
    System.runAs(new User(Id = userinfo.getUserId())) {
      List<ObjectTerritory2Association> ota = new List<ObjectTerritory2Association>();
      ota.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = parrterr.Id,
          AssociationCause = 'Territory2Manual'
        )
      );

      ota.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[1].Id,
          Territory2Id = accterr.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert ota;
    }
    List<Opportunity> oppList = TestFactory_ET.createOpportunities(1, accountList[1].Id, 'CPQ_Default', false);

    insert oppList;
    List<Opportunity> updatedOppList = [
      SELECT
        Id,
        Name,
        Territory2.Sales_Territory__c,
        Territory2.Sales_Area__c,
        OwnerId,
        Territory2.Primary_Account_Manager_Id__c,
        Is_Partner_Sourced__c,
        BPO_MS_End_Customer__c,
        Territory2.Interim_Account_Manager_Id__c,
        Deal_Type__c,
        Territory2Id,
        BPO_MS_End_Customer__r.RecordTypeId,
        AccountId,
        Account.RecordTypeId,
        Territory_Geo__c,
        Owner_Sync_Status__c,
        Account_Geo__c
      FROM Opportunity
    ];
    updatedOppList[0].Territory2 = terr;
    updatedOppList[0].Territory2Id = terr.Id;
    //update updatedOppList;

    Test.startTest();
    OpportunityCompensationService_ET batch = new OpportunityCompensationService_ET();
    batch.syncOpportunitySplit(updatedOppList);
    Test.stopTest();
    List<Opportunity_Split__c> oppSplit = [
      SELECT Id, Opportunity__c, TeamMemberRole__c
      FROM Opportunity_Split__c
      WHERE Opportunity__c = :updatedOppList[0].Id
    ];
    System.assertEquals(2, oppSplit.size(), 'Opportunity Split Created');
  }

  public static testMethod void createOppSplitsForManagedServiceRPM() {
    setupdata();
    Territory2 oppterr = TestFactory_ET.getTerritoryId('Test Sales Territory 7');
    Territory2 accterr = TestFactory_ET.getTerritoryId('Test Sales Territory 8');

    List<Account> acList = new List<Account>();
    List<Account> accountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 8', false);
    List<Account> oppaccountList = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 1', false);
    acList.addall(accountList);
    acList.addall(oppaccountList);
    insert acList;
    System.runAs(new User(Id = userinfo.getUserId())) {
      List<ObjectTerritory2Association> ota = new List<ObjectTerritory2Association>();
      ota.add(
        new ObjectTerritory2Association(
          ObjectId = accountList[0].Id,
          Territory2Id = accterr.Id,
          AssociationCause = 'Territory2Manual'
        )
      );

      insert ota;
    }
    List<Opportunity> partnerOppList = TestFactory_ET.createOpportunities(
      1,
      oppaccountList[0].Id,
      'UiPath_Standard',
      false
    );
    partnerOppList[0].LeadSource = 'Webinar';
    partnerOppList[0].StageName = 'Discovery';
    partnerOppList[0].CloseDate = date.newInstance(2160, 2, 17);
    partnerOppList[0].BPO_MS_End_Customer__c = accountList[0].Id;
    partnerOppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_MANAGED_SERVICES;
    insert partnerOppList;
    //system.debug('partnerOppList' + partnerOppList);
    List<Opportunity> updatedPartOppList = [
      SELECT
        Id,
        Name,
        Territory2.Sales_Territory__c,
        Territory2.Ultimate_Geo__c,
        Territory2.Area__c,
        Territory2.Region__c,
        Territory2.Sales_Area__c,
        Territory2.Sales_Geo__c,
        Territory2.Sales_Region__c,
        OwnerId,
        Territory2.Primary_Account_Manager_Id__c,
        Is_Partner_Sourced__c,
        BPO_MS_End_Customer__c,
        Territory2.Interim_Account_Manager_Id__c,
        Deal_Type__c,
        BPO_MS_End_Customer__r.RecordTypeId,
        AccountId,
        Account.RecordTypeId,
        Territory_Geo__c,
        Owner_Sync_Status__c,
        Account_Geo__c
      FROM Opportunity
    ];
    updatedPartOppList[0].Territory2 = oppterr;
    updatedPartOppList[0].Territory2Id = oppterr.Id;

    Test.startTest();
    OpportunityCompensationService_ET batch = new OpportunityCompensationService_ET();
    batch.syncOpportunitySplit(updatedPartOppList);
    Test.stopTest();
    List<Opportunity_Split__c> partoppSplit = [
      SELECT Id, Opportunity__c, TeamMemberRole__c
      FROM Opportunity_Split__c
      WHERE Opportunity__c = :updatedPartOppList[0].Id
    ];

    System.assertEquals(2, partoppSplit.size(), 'Opportunity Split Created');
  }

  public static testMethod void createOppSplitsForPartners() {
    setupdata();
    Territory2 oppterr = TestFactory_ET.getTerritoryId('Test Sales Territory 7');
    Territory2 partaccterr = TestFactory_ET.getTerritoryId('Test Sales Territory 5');

    Id partnerRecTypeId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Partner')
      .getRecordTypeId();

    List<Account> partneraccountList = TestFactory_ET.createAccounts(1, 'Partner', 'Test Sales Territory 5', false);
    insert partneraccountList;
    System.runAs(new User(Id = userinfo.getUserId())) {
      List<ObjectTerritory2Association> ota = new List<ObjectTerritory2Association>();
      ota.add(
        new ObjectTerritory2Association(
          ObjectId = partneraccountList[0].Id,
          Territory2Id = partaccterr.Id,
          AssociationCause = 'Territory2Manual'
        )
      );

      insert ota;
    }
    List<Opportunity> partnerOppList = TestFactory_ET.createOpportunities(
      1,
      partneraccountList[0].Id,
      'UiPath_Standard',
      false
    );
    partnerOppList[0].LeadSource = 'Webinar';
    partnerOppList[0].StageName = 'Discovery';
    partnerOppList[0].CloseDate = date.newInstance(2160, 2, 17);
    partnerOppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_BPO;
    insert partnerOppList;
    //system.debug('partnerOppList' + partnerOppList);
    List<Opportunity> updatedPartOppList = [
      SELECT
        Id,
        Name,
        Territory2.Sales_Territory__c,
        Territory2.Ultimate_Geo__c,
        Territory2.Area__c,
        Territory2.Region__c,
        Territory2.Sales_Area__c,
        Territory2.Sales_Geo__c,
        Territory2.Sales_Region__c,
        OwnerId,
        BPO_MS_End_Customer__r.RecordTypeId,
        Territory2.Primary_Account_Manager_Id__c,
        Is_Partner_Sourced__c,
        BPO_MS_End_Customer__c,
        Territory2.Interim_Account_Manager_Id__c,
        Deal_Type__c,
        AccountId,
        Account.RecordTypeId,
        Territory_Geo__c,
        Owner_Sync_Status__c,
        Account_Geo__c
      FROM Opportunity
    ];
    updatedPartOppList[0].Territory2 = oppterr;
    updatedPartOppList[0].Territory2Id = oppterr.Id;

    Test.startTest();
    OpportunityCompensationService_ET batch = new OpportunityCompensationService_ET();
    batch.syncOpportunitySplit(updatedPartOppList);
    Test.stopTest();
    List<Opportunity_Split__c> partoppSplit = [
      SELECT Id, Opportunity__c, TeamMemberRole__c
      FROM Opportunity_Split__c
      WHERE Opportunity__c = :updatedPartOppList[0].Id
    ];

    System.assertEquals(2, partoppSplit.size(), 'Opportunity Split Created');
  }

  public static testMethod void createOppSplitsForPartnersRPM() {
    DataFactory_SL.createQuoteApprovalMatrix('EMEA', UserInfo.getUserId(), 'Influence', 'Operations', 'Region', true);
    Territory2 oppterr;
    Territory2 partaccterr;
    System.runAs(new User(Id = userinfo.getuserId())) {
      Territory2Type objTerrType = [SELECT Id, DeveloperName FROM Territory2Type LIMIT 1];
      List<Territory2> terrList = new List<Territory2>();
      oppterr = new Territory2(
        Name = 'Test Sales Territory 3',
        Sales_Territory__c = true,
        Ultimate_Geo__c = 'EMEA',
        Territory2ModelId = TestFactory_ET.getActiveTerritoryModelId(),
        Territory2TypeId = objTerrType.id,
        DeveloperName = 'Test Sales Territory 3'.replace(' ', '_')
      );
      terrList.add(oppterr);
      Territory2Type partnerTerrType = [
        SELECT Id, DeveloperName
        FROM Territory2Type
        WHERE MasterLabel = :ETMConstant.PARTNER_MANAGEMENT
      ];
      partaccterr = new Territory2(
        Name = 'Test non-Sales Territory 6',
        Ultimate_Geo__c = 'EMEA',
        Territory2ModelId = TestFactory_ET.getActiveTerritoryModelId(),
        Territory2TypeId = partnerTerrType.id,
        DeveloperName = 'Test Sales Territory 6'.replace(' ', '_')
      );
      terrList.add(partaccterr);
      insert terrList;

      List<User> userList = new List<User>();

      for (Integer i = 0; i < 3; i++) {
        User objUser = new User();
        objUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        objUser.Username = 'test839734@' + i + 'uiath.com';
        objUser.LastName = 'Test';
        objUser.Email = 'test839734@uiath.com';
        objUser.Alias = 't839734';
        objUser.TimeZoneSidKey = 'America/Los_Angeles';
        objUser.LocaleSidKey = 'en_US';
        objUser.EmailEncodingKey = 'UTF-8';
        objUser.LanguageLocaleKey = 'en_US';
        userList.add(objUser);
      }
      insert userList;
      List<UserTerritory2Association> userAssList = new List<UserTerritory2Association>();

      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = partaccterr.Id,
          UserId = userList[0].Id,
          RoleInTerritory2 = ETMConstant.GSI_PARTNER_MANAGER
        )
      );
      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = partaccterr.Id,
          UserId = userList[1].Id,
          RoleInTerritory2 = ETMConstant.SEC_GSI_PARTNER_MANAGER
        )
      );
      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = oppterr.Id,
          UserId = userList[2].Id,
          RoleInTerritory2 = ETMConstant.REGION_PARTNER_MANAGER
        )
      );

      insert userAssList;
    }
    Id partnerRecTypeId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Partner')
      .getRecordTypeId();

    List<Account> accntList = new List<Account>();
    List<Account> partneraccount = TestFactory_ET.createAccounts(1, 'Partner', 'Test Sales Territory 6', false);
    partneraccount[0].Regional_Business_Partner_Type__c = 'RSI';
    accntList.add(partneraccount[0]);
    List<Account> oppaccount = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 2', false);
    accntList.add(oppaccount[0]);
    insert accntList;

    System.runAs(new User(Id = Userinfo.getUserId())) {
      Territory2Model objTerrModel = [SELECT Id, DeveloperName FROM Territory2Model LIMIT 1];
      Territory2Type objTerrType = [
        SELECT Id, DeveloperName
        FROM Territory2Type
        WHERE DeveloperName = 'Velocity'
        LIMIT 1
      ];

      Territory2 EMEATerritory = new Territory2();
      EMEATerritory.AccountAccessLevel = 'Edit';
      EMEATerritory.CaseAccessLevel = 'Read';
      EMEATerritory.Name = 'EMEA Territory';
      EMEATerritory.DeveloperName = 'EMEA_Territory';
      EMEATerritory.Territory2ModelId = objTerrModel.Id;
      EMEATerritory.Ultimate_Geo__c = 'EMEA';
      EMEATerritory.Sales_Territory__c = true;
      EMEATerritory.Area__c = 'EMEA Area';
      EMEATerritory.Region__c = 'EMEA Region';
      EMEATerritory.Territory2TypeId = objTerrType.Id;
      insert EMEATerritory;

      UserTerritory2Association objUserTerrAssEMEA = new UserTerritory2Association();
      objUserTerrAssEMEA.RoleInTerritory2 = ETMConstant.PRIMARY_ACCOUNT_MANAGER;
      objUserTerrAssEMEA.UserId = UserInfo.getUserId();
      objUserTerrAssEMEA.Territory2Id = EMEATerritory.Id;
      insert objUserTerrAssEMEA;

      List<ObjectTerritory2Association> ota = new List<ObjectTerritory2Association>();
      ota.add(
        new ObjectTerritory2Association(
          ObjectId = partneraccount[0].Id,
          Territory2Id = partaccterr.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      ota.add(
        new ObjectTerritory2Association(
          ObjectId = oppaccount[0].Id,
          Territory2Id = EMEATerritory.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert ota;
    }
    List<Opportunity> partnerOppList = TestFactory_ET.createOpportunities(
      1,
      oppaccount[0].Id,
      'UiPath_Standard',
      false
    );
    partnerOppList[0].LeadSource = 'Webinar';
    partnerOppList[0].StageName = 'Discovery';
    partnerOppList[0].CloseDate = date.newInstance(2160, 2, 17);
    partnerOppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_BPO;

    insert partnerOppList;

    Test.startTest();

    Partner_Involvement__c newPartner2 = TestFactory_ET.createPartnerInvolvement(
      partnerOppList[0].Id,
      'Influence (No Financial Comp from UiPath)',
      false
    );
    newPartner2.Opportunity_Sourced__c = true;
    newPartner2.Partner_Account_Name__c = partneraccount[0].Id;
    insert newPartner2;

    List<Opportunity> updatedPartOppList = [
      SELECT
        Id,
        Name,
        Territory2.Sales_Territory__c,
        OwnerId,
        Territory2.Primary_Account_Manager_Id__c,
        Is_Partner_Sourced__c,
        Territory2.Sales_Area__c,
        BPO_MS_End_Customer__c,
        Territory2.Interim_Account_Manager_Id__c,
        BPO_MS_End_Customer__r.RecordTypeId,
        Deal_Type__c,
        AccountId,
        Account.RecordTypeId,
        Territory_Geo__c,
        Owner_Sync_Status__c,
        Account_Geo__c
      FROM Opportunity
    ];
    updatedPartOppList[0].Territory2 = oppterr;
    updatedPartOppList[0].Territory2Id = oppterr.Id;
    updatedPartOppList[0].Is_Partner_Sourced__c = true;
    OpportunityCompensationService_ET batch = new OpportunityCompensationService_ET();
    batch.syncOpportunitySplit(updatedPartOppList);
    Test.stopTest();
    List<Opportunity_Split__c> partoppSplit = [
      SELECT Id, Opportunity__c, TeamMemberRole__c
      FROM Opportunity_Split__c
      WHERE Opportunity__c = :updatedPartOppList[0].Id
    ];

    System.assertEquals(4, partoppSplit.size(), 'Opportunity Split Created');
  }

  public static testMethod void createOppSplitsForPartnersRegionRPM() {
    DataFactory_SL.createQuoteApprovalMatrix('EMEA', UserInfo.getUserId(), 'Influence', 'Operations', 'Region', true);
    Territory2 oppterr;
    Territory2 partaccterr;
    System.runAs(new User(Id = userinfo.getuserId())) {
      Territory2 regionTerr = TestFactory_ET.initTerritory('EMEA1', 'Area1', 'Region1');
      Territory2Type objTerrType = [SELECT Id, DeveloperName FROM Territory2Type LIMIT 1];
      List<Territory2> terrList = new List<Territory2>();
      oppterr = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 3', false);

      terrList.add(oppterr);
      Territory2Type partnerTerrType = [
        SELECT Id, DeveloperName
        FROM Territory2Type
        WHERE MasterLabel = :ETMConstant.PARTNER_MANAGEMENT
      ];

      partaccterr = TestFactory_ET.createNonSalesTerritory(regionTerr, 'Test Non Sales Territory 8', false);
      partaccterr.Territory2TypeId = partnerTerrType.id;
      terrList.add(partaccterr);
      insert terrList;

      List<User> userList = new List<User>();

      for (Integer i = 0; i < 3; i++) {
        User objUser = new User();
        objUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        objUser.Username = 'test839734@' + i + 'uiath.com';
        objUser.LastName = 'Test';
        objUser.Email = 'test839734@uiath.com';
        objUser.Alias = 't839734';
        objUser.TimeZoneSidKey = 'America/Los_Angeles';
        objUser.LocaleSidKey = 'en_US';
        objUser.EmailEncodingKey = 'UTF-8';
        objUser.LanguageLocaleKey = 'en_US';
        userList.add(objUser);
      }
      insert userList;
      List<UserTerritory2Association> userAssList = new List<UserTerritory2Association>();

      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = partaccterr.Id,
          UserId = userList[0].Id,
          RoleInTerritory2 = ETMConstant.GLOBAL_GSI_PARTNER_MANAGER
        )
      );

      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = oppterr.Id,
          UserId = userList[2].Id,
          RoleInTerritory2 = ETMConstant.REGION_PARTNER_MANAGER
        )
      );

      insert userAssList;
    }
    Id partnerRecTypeId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Partner')
      .getRecordTypeId();

    List<Account> accntList = new List<Account>();
    List<Account> partneraccount = TestFactory_ET.createAccounts(1, 'Partner', 'Test Sales Territory 6', false);
    partneraccount[0].Regional_Business_Partner_Type__c = 'RSI';
    accntList.add(partneraccount[0]);
    List<Account> oppaccount = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 2', false);
    accntList.add(oppaccount[0]);
    insert accntList;

    System.runAs(new User(Id = Userinfo.getUserId())) {
      Territory2Model objTerrModel = [SELECT Id, DeveloperName FROM Territory2Model LIMIT 1];
      Territory2Type objTerrType = [
        SELECT Id, DeveloperName
        FROM Territory2Type
        WHERE DeveloperName = 'Velocity'
        LIMIT 1
      ];

      Territory2 EMEATerritory = new Territory2();
      EMEATerritory.AccountAccessLevel = 'Edit';
      EMEATerritory.CaseAccessLevel = 'Read';
      EMEATerritory.Name = 'EMEA Territory';
      EMEATerritory.DeveloperName = 'EMEA_Territory';
      EMEATerritory.Territory2ModelId = objTerrModel.Id;
      EMEATerritory.Ultimate_Geo__c = 'EMEA';
      EMEATerritory.Sales_Territory__c = true;
      EMEATerritory.Area__c = 'EMEA Area';
      EMEATerritory.Region__c = 'EMEA Region';
      EMEATerritory.Territory2TypeId = objTerrType.Id;
      insert EMEATerritory;

      UserTerritory2Association objUserTerrAssEMEA = new UserTerritory2Association();
      objUserTerrAssEMEA.RoleInTerritory2 = ETMConstant.PRIMARY_ACCOUNT_MANAGER;
      objUserTerrAssEMEA.UserId = UserInfo.getUserId();
      objUserTerrAssEMEA.Territory2Id = EMEATerritory.Id;
      insert objUserTerrAssEMEA;

      List<ObjectTerritory2Association> ota = new List<ObjectTerritory2Association>();
      ota.add(
        new ObjectTerritory2Association(
          ObjectId = partneraccount[0].Id,
          Territory2Id = partaccterr.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      ota.add(
        new ObjectTerritory2Association(
          ObjectId = oppaccount[0].Id,
          Territory2Id = EMEATerritory.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert ota;
    }
    List<Opportunity> partnerOppList = TestFactory_ET.createOpportunities(
      1,
      oppaccount[0].Id,
      'UiPath_Standard',
      false
    );
    partnerOppList[0].LeadSource = 'Webinar';
    partnerOppList[0].StageName = 'Discovery';
    partnerOppList[0].CloseDate = date.newInstance(2160, 2, 17);
    partnerOppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_BPO;

    insert partnerOppList;

    Test.startTest();

    Partner_Involvement__c newPartner2 = TestFactory_ET.createPartnerInvolvement(
      partnerOppList[0].Id,
      'Influence (No Financial Comp from UiPath)',
      false
    );
    newPartner2.Opportunity_Sourced__c = true;
    newPartner2.Partner_Account_Name__c = partneraccount[0].Id;
    insert newPartner2;

    List<Opportunity> updatedPartOppList = [
      SELECT
        Id,
        Name,
        Territory2.Sales_Territory__c,
        Territory2.Sales_Area__c,
        OwnerId,
        Territory2.Primary_Account_Manager_Id__c,
        Is_Partner_Sourced__c,
        BPO_MS_End_Customer__c,
        Territory2.Interim_Account_Manager_Id__c,
        Deal_Type__c,
        BPO_MS_End_Customer__r.RecordTypeId,
        AccountId,
        Account.RecordTypeId,
        Territory_Geo__c,
        Owner_Sync_Status__c,
        Account_Geo__c
      FROM Opportunity
    ];
    updatedPartOppList[0].Territory2 = oppterr;
    updatedPartOppList[0].Territory2Id = oppterr.Id;
    updatedPartOppList[0].Is_Partner_Sourced__c = true;
    OpportunityCompensationService_ET batch = new OpportunityCompensationService_ET();
    batch.syncOpportunitySplit(updatedPartOppList);
    Test.stopTest();
    List<Opportunity_Split__c> partoppSplit = [
      SELECT Id, Opportunity__c, TeamMemberRole__c
      FROM Opportunity_Split__c
      WHERE Opportunity__c = :updatedPartOppList[0].Id
    ];

    System.assertEquals(3, partoppSplit.size(), 'Opportunity Split Created');
  }

  public static testMethod void createOppSplitsForPartnersVAC() {
    DataFactory_SL.createQuoteApprovalMatrix('EMEA', UserInfo.getUserId(), 'Influence', 'Operations', 'Region', true);
    Territory2 oppterr;
    Territory2 partaccterr;
    System.runAs(new User(Id = userinfo.getuserId())) {
      Territory2 regionTerr = TestFactory_ET.initTerritory('EMEA2', 'Area2', 'Region2');
      Territory2Type objTerrType = [SELECT Id, DeveloperName FROM Territory2Type LIMIT 1];

      List<Territory2> terrList = new List<Territory2>();

      oppterr = TestFactory_ET.createSalesTerritory(regionTerr, 'Test Sales Territory 3', false);

      terrList.add(oppterr);
      Territory2Type partnerTerrType = [
        SELECT Id, DeveloperName
        FROM Territory2Type
        WHERE MasterLabel = :ETMConstant.PARTNER_MANAGEMENT
      ];

      partaccterr = TestFactory_ET.createNonSalesTerritory(regionTerr, 'Test Non Sales Territory 8', false);
      partaccterr.Territory2TypeId = partnerTerrType.id;
      terrList.add(partaccterr);
      insert terrList;

      List<User> userList = new List<User>();

      for (Integer i = 0; i < 3; i++) {
        User objUser = new User();
        objUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        objUser.Username = 'test839734@' + i + 'uiath.com';
        objUser.LastName = 'Test';
        objUser.Email = 'test839734@uiath.com';
        objUser.Alias = 't839734';
        objUser.TimeZoneSidKey = 'America/Los_Angeles';
        objUser.LocaleSidKey = 'en_US';
        objUser.EmailEncodingKey = 'UTF-8';
        objUser.LanguageLocaleKey = 'en_US';
        userList.add(objUser);
      }
      insert userList;
      List<UserTerritory2Association> userAssList = new List<UserTerritory2Association>();

      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = partaccterr.Id,
          UserId = userList[0].Id,
          RoleInTerritory2 = ETMConstant.VACANT_TERR_COMP_PART_MANAGER
        )
      );

      userAssList.add(
        new UserTerritory2Association(
          Territory2Id = oppterr.Id,
          UserId = userList[2].Id,
          RoleInTerritory2 = ETMConstant.REGION_PARTNER_MANAGER
        )
      );

      insert userAssList;
    }
    Id partnerRecTypeId = Schema.SobjectType.Account.getRecordTypeInfosByDeveloperName()
      .get('Partner')
      .getRecordTypeId();

    List<Account> accntList = new List<Account>();
    List<Account> partneraccount = TestFactory_ET.createAccounts(1, 'Partner', 'Test Sales Territory 6', false);
    partneraccount[0].Regional_Business_Partner_Type__c = 'RSI';
    accntList.add(partneraccount[0]);
    List<Account> oppaccount = TestFactory_ET.createAccounts(1, 'Customer', 'Test Sales Territory 2', false);
    accntList.add(oppaccount[0]);
    insert accntList;

    System.runAs(new User(Id = Userinfo.getUserId())) {
      Territory2Model objTerrModel = [SELECT Id, DeveloperName FROM Territory2Model LIMIT 1];
      Territory2Type objTerrType = [
        SELECT Id, DeveloperName
        FROM Territory2Type
        WHERE DeveloperName = 'Velocity'
        LIMIT 1
      ];

      Territory2 EMEATerritory = new Territory2();
      EMEATerritory.AccountAccessLevel = 'Edit';
      EMEATerritory.CaseAccessLevel = 'Read';
      EMEATerritory.Name = 'EMEA Territory';
      EMEATerritory.DeveloperName = 'EMEA_Territory';
      EMEATerritory.Territory2ModelId = objTerrModel.Id;
      EMEATerritory.Ultimate_Geo__c = 'EMEA';
      EMEATerritory.Sales_Territory__c = true;
      EMEATerritory.Area__c = 'EMEA Area';
      EMEATerritory.Region__c = 'EMEA Region';
      EMEATerritory.Territory2TypeId = objTerrType.Id;
      insert EMEATerritory;

      UserTerritory2Association objUserTerrAssEMEA = new UserTerritory2Association();
      objUserTerrAssEMEA.RoleInTerritory2 = ETMConstant.PRIMARY_ACCOUNT_MANAGER;
      objUserTerrAssEMEA.UserId = UserInfo.getUserId();
      objUserTerrAssEMEA.Territory2Id = EMEATerritory.Id;
      insert objUserTerrAssEMEA;

      List<ObjectTerritory2Association> ota = new List<ObjectTerritory2Association>();
      ota.add(
        new ObjectTerritory2Association(
          ObjectId = partneraccount[0].Id,
          Territory2Id = partaccterr.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      ota.add(
        new ObjectTerritory2Association(
          ObjectId = oppaccount[0].Id,
          Territory2Id = EMEATerritory.Id,
          AssociationCause = 'Territory2Manual'
        )
      );
      insert ota;
    }
    List<Opportunity> partnerOppList = TestFactory_ET.createOpportunities(
      1,
      oppaccount[0].Id,
      'UiPath_Standard',
      false
    );
    partnerOppList[0].LeadSource = 'Webinar';
    partnerOppList[0].StageName = 'Discovery';
    partnerOppList[0].CloseDate = date.newInstance(2160, 2, 17);
    partnerOppList[0].Deal_Type__c = ETMConstant.DEAL_TYPE_BPO;

    insert partnerOppList;

    Test.startTest();

    Partner_Involvement__c newPartner2 = TestFactory_ET.createPartnerInvolvement(
      partnerOppList[0].Id,
      'Influence (No Financial Comp from UiPath)',
      false
    );
    newPartner2.Opportunity_Sourced__c = true;
    newPartner2.Partner_Account_Name__c = partneraccount[0].Id;
    insert newPartner2;

    List<Opportunity> updatedPartOppList = [
      SELECT
        Id,
        Name,
        Territory2.Sales_Territory__c,
        Territory2.Sales_Area__c,
        OwnerId,
        Territory2.Primary_Account_Manager_Id__c,
        Is_Partner_Sourced__c,
        BPO_MS_End_Customer__c,
        Territory2.Interim_Account_Manager_Id__c,
        Deal_Type__c,
        BPO_MS_End_Customer__r.RecordTypeId,
        AccountId,
        Account.RecordTypeId,
        Territory_Geo__c,
        Owner_Sync_Status__c,
        Account_Geo__c
      FROM Opportunity
    ];
    updatedPartOppList[0].Territory2 = oppterr;
    updatedPartOppList[0].Territory2Id = oppterr.Id;
    updatedPartOppList[0].Is_Partner_Sourced__c = true;
    OpportunityCompensationService_ET batch = new OpportunityCompensationService_ET();
    batch.syncOpportunitySplit(updatedPartOppList);
    Test.stopTest();
    List<Opportunity_Split__c> partoppSplit = [
      SELECT Id, Opportunity__c, TeamMemberRole__c
      FROM Opportunity_Split__c
      WHERE Opportunity__c = :updatedPartOppList[0].Id
    ];

    System.assertEquals(3, partoppSplit.size(), 'Opportunity Split Created');
  }
}