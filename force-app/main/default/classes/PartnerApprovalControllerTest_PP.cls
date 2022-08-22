@IsTest
private class PartnerApprovalControllerTest_PP {
  public static final String ACCOUNT_ERROR_MESSAGE = 'Incorrect amount of expected accounts created after lead conversion';
  @IsTest
  static void isShouldActivateThePartner() {
    // GIVEN a lead and a Partner Application form
    Lead lead = generateLead();
    Partner_Application_Form__c form = generateForm(lead);
    insert form;

    // WHEN the application is approved
    List<PartnerApprovalController_PP.approvePartnerApplicationRequest> requests = callController(form);
    PartnerApprovalController_PP.approvePartnerApplication(requests);

    // THEN the lead should be converted
    System.assertEquals('Approved', form.UiPath_Status__c, 'Incorrect approval status');
    System.assertEquals(
      1,
      [SELECT COUNT() FROM Contact],
      'Incorrect amount of expected contacts created after lead conversion'
    );
    System.assertEquals(1, [SELECT COUNT() FROM Account], ACCOUNT_ERROR_MESSAGE);
    System.assertEquals(
      1,
      [SELECT COUNT() FROM Account WHERE Partner_Application_Form__c = :form.Id],
      ACCOUNT_ERROR_MESSAGE
    );
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Opportunity],
      'Incorrect amount of expected opportunities created after lead conversion'
    );
  }

  @IsTest
  static void isShouldActivateThePartnerAndCreateContactForAuthorisedSignatory() {
    // GIVEN a lead and a Partner Application form
    Lead lead = generateLead();
    Partner_Application_Form__c form = generateForm(lead);
    form.Authorized_Signatory_Name__c = 'Jane Smith';
    form.Authorized_Signatory_Title__c = 'Director';
    form.Authorized_Signatory_Email__c = 'ceo@example.com';
    form.Authorized_Signatory_Phone__c = '+198765432';
    insert form;

    // WHEN the application is approved
    Test.startTest();
    List<PartnerApprovalController_PP.approvePartnerApplicationRequest> requests = callController(form);
    PartnerApprovalController_PP.approvePartnerApplication(requests);
    Test.stopTest();

    // THEN the lead should be converted
    List<Contact> contacts = [SELECT Id, Role__c FROM Contact];
    System.assertEquals('Approved', form.UiPath_Status__c, 'Incorrect approval status');
    System.assertEquals(2, contacts.size(), 'Incorrect amount of expected contacts created after lead conversion');
    System.assertEquals(1, [SELECT COUNT() FROM Account], ACCOUNT_ERROR_MESSAGE);
    System.assertEquals(
      'Partner',
      [SELECT RecordType.Name FROM Account][0]
      .RecordType.Name,
      'Incorrect recordtype name'
    );
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Opportunity],
      'Incorrect amount of expected opportunities created after lead conversion'
    );
    Integer authorisedSignatories = 0;
    for (Contact contact : contacts) {
      if (contact.Role__c == 'Authorised Signatory')
        authorisedSignatories++;
    }
    System.assertEquals(1, authorisedSignatories, 'Incorrect amount of authorised Signatory contacts');
  }

  private static List<PartnerApprovalController_PP.approvePartnerApplicationRequest> callController(
    Partner_Application_Form__c form
  ) {
    PartnerApprovalController_PP.approvePartnerApplicationRequest request = new PartnerApprovalController_PP.approvePartnerApplicationRequest();
    request.partnerApplicationFormId = form.Id;

    return new List<PartnerApprovalController_PP.approvePartnerApplicationRequest>{ request };
  }

  private static Lead generateLead() {
    Lead lead = new Lead(
      Company = 'John Smith & Co.',
      Country = 'Ireland',
      Department1__c = 'Administration and Management',
      Department__c = 'IT',
      Email = 'john.smith@example.com',
      FirstName = 'John',
      First_Interaction__c = 'Website Form',
      First_Interaction_Details__c = 'Partner',
      Industry = 'Banking and Financial Services',
      Job_Level__c = 'Executive/ C-Level',
      LastName = 'Smith',
      //				Lead_Vertical__c = 'Banking and Financial Services',
      RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Business Partner').getRecordTypeId(),
      Tier__c = '1',
      Title = 'Founder',
      Territory__c = 'Canada',
      Geo__c = 'AMER'
    );
    insert lead;
    return lead;
  }

  private static Partner_Application_Form__c generateForm(Lead lead) {
    Partner_Application_Form__c form = new Partner_Application_Form__c(
      Application_Status__c = 'new',
      Contact_Type__c = 'Business Process Owner',
      Lead__c = lead.Id,
      Email__c = 'john.smith@example.com',
      Partner_Type__c = 'Managed Services Partner (MSP)',
      Phone__c = '+123456789',
      UiPath_Status__c = 'Approved',
      UiPath_Sub_Status__c = 'New Master Partner Agreement'
    );
    return form;
  }
}