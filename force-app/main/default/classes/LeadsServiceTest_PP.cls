@IsTest
private class LeadsServiceTest_PP {
  @IsTest
  static void itShouldConvertPartnerUserLead() {
    // given
    User systemAdminUser;
    User systemContextUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

    String suffix = Datetime.now().format('yyMMdd') + 'TEST';

    System.runAs(systemContextUser) {
      String roleName = 'role' + suffix;
      UserRole role = new UserRole(DeveloperName = roleName, Name = roleName);
      insert role;

      systemAdminUser = new User();
      systemAdminUser.Alias = 'mkats';
      systemAdminUser.Email = 'mkatsuragi@example.com' + suffix;
      systemAdminUser.EmailEncodingKey = 'UTF-8';
      systemAdminUser.LastName = 'User';
      systemAdminUser.FirstName = 'Misato';
      systemAdminUser.LanguageLocaleKey = 'en_US';
      systemAdminUser.LocaleSidKey = 'en_US';
      systemAdminUser.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
      systemAdminUser.TimeZoneSidKey = 'GMT';
      systemAdminUser.Username = 'mkatsuragi@example.com' + suffix;
      systemAdminUser.Country = 'Belgium';
      systemAdminUser.UserRoleId = role.Id;
      insert systemAdminUser;
    }

    Id leadBusinessPartnerRecordTypeId = Schema.SObjectType.Lead
      .getRecordTypeInfosByDeveloperName()
      .get('Business_Partner_Onboarding')
      .getRecordTypeId();

    Id leadStandardRecordTypeId = Schema.SObjectType.Lead
      .getRecordTypeInfosByDeveloperName()
      .get('Standard')
      .getRecordTypeId();

    Account partnerAccount = new Account();
    partnerAccount.Name = 'NERV';
    partnerAccount.BillingCountry = 'United States';
    partnerAccount.Industry = 'Technology';
    partnerAccount.OwnerId = systemAdminUser.Id;
    insert partnerAccount;

    User partnerUser = new User();
    partnerUser.FirstName = 'Rei';
    partnerUser.LastName = 'Ayanami';
    partnerUser.Email = 'rayanami@example.com';

    Lead partnerLead = new Lead();
    partnerLead.RecordTypeId = leadStandardRecordTypeId;
    partnerLead.Status = 'Suspect';
    partnerLead.Overwrite_Account_Match__c = false;
    partnerLead.Email = 'alangley@example.com';
    partnerLead.FirstName = 'Asuka';
    partnerLead.MiddleName = '';
    partnerLead.LastName = 'Langley';
    partnerLead.Company = 'NERV';
    partnerLead.Country = 'United States';
    partnerLead.Department__c = 'IT';
    partnerLead.Department1__c = 'IT';
    insert partnerLead;

    LeadsService_PP leadsService = (LeadsService_PP) Application_PP.Service.newInstance(LeadsService_PP.class);
    LeadsSelector_PP leadsSelector = (LeadsSelector_PP) Application_PP.Selector.newInstance(Lead.SObjectType);

    // when
    Test.startTest();
    Database.LeadConvertResult leadConvertResult = leadsService.convertPartnerUserLead(
      partnerLead,
      partnerUser,
      partnerAccount
    );
    Test.stopTest();

    // then
    List<Lead> leads = leadsSelector.selectByEmail(new Set<String>{ partnerUser.Email }, false);

    System.assertEquals(true, leadConvertResult.isSuccess());
    System.assertEquals(false, leads.isEmpty());
    System.assertEquals(partnerUser.FirstName, leads.get(0).FirstName);
    System.assertEquals(partnerUser.LastName, leads.get(0).LastName);
    System.assertEquals(partnerUser.Email, leads.get(0).Email);
    System.assertEquals(leadBusinessPartnerRecordTypeId, leads.get(0).RecordTypeId);
    System.assertEquals(LeadsService_PP.CONVERT_PARTNER_USER_LEAD_STATUS, leads.get(0).Status);
    System.assertEquals(true, leads.get(0).Overwrite_Account_Match__c);
    System.assertEquals(partnerAccount.Id, leads.get(0).Account__c);
  }

  @IsTest
  static void itShouldUpdatePAFOwner() {
    // given
    User testOwner = new User();
    String suffix = Datetime.now().format('yyMMdd') + 'TEST';
    testOwner.FirstName = 'Test';
    testOwner.LastName = 'Owner';
    testOwner.Email = 'testOwner@uipath.com';
    testOwner.Alias = 'mkats';
    testOwner.EmailEncodingKey = 'UTF-8';
    testOwner.LanguageLocaleKey = 'en_US';
    testOwner.LocaleSidKey = 'en_US';
    testOwner.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
    testOwner.TimeZoneSidKey = 'GMT';
    testOwner.Username = 'testOwner@uipath.com' + suffix;
    testOwner.Country = 'Belgium';
    insert testOwner;

    Lead lead = new Lead();
    lead.LastName = 'TestUpdate';
    lead.Company = 'TestCompany';
    lead.Email = 'TestCompany@something.uipath.com';
    lead.Country = 'Romania';
    lead.Department1__c = 'IT';
    lead.Department__c = 'IT';
    insert lead;

    Partner_Application_Form__c partnerApplicationForm = new Partner_Application_Form__c();
    partnerApplicationForm.Lead__c = lead.Id;
    insert partnerApplicationForm;

    // when
    Test.startTest();
    lead.OwnerId = testOwner.Id;
    update lead;
    Test.stopTest();

    // then
    Partner_Application_Form__c partnerApplicationFormUpdated = [
      SELECT Id, OwnerId
      FROM Partner_Application_Form__c
      WHERE Id = :partnerApplicationForm.Id
    ];
    System.assert(partnerApplicationFormUpdated.OwnerId == testOwner.Id);
  }

  @IsTest
  static void itShouldDisableOwnerChange() {
    //given
    Lead lead = new Lead();
    lead.LastName = 'TestUpdate';
    lead.Company = 'TestCompany';
    lead.Email = 'TestCompany@something.uipath.com';
    lead.Country = 'Romania';
    lead.Department1__c = 'IT';
    lead.Department__c = 'IT';
    insert lead;

    lead = [SELECT Id, Disable_Owner_Change__c FROM Lead WHERE Id = :lead.Id];
    System.assert(lead.Disable_Owner_Change__c == false);

    // when
    Test.startTest();
    LeadsService_PP.updateRelatedLeadToAvoidAutoReassign(new Set<Id>{ lead.Id });
    Test.stopTest();

    // then
    lead = [SELECT Id, Disable_Owner_Change__c FROM Lead WHERE Id = :lead.Id];
    System.assert(lead.Disable_Owner_Change__c == true);
  }
}