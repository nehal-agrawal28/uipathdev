public without sharing class EmailsService_PP {
  public static final String PARTNER_SELFREGISTRATION_VERIFICATION_CODE = 'PartnerSelfRegistrationVerificationCode';
  public static final String DEAL_REGISTRATION_DRAFT_NOTIFICATION = 'Deal_Registration_Draft_Notification';
  public static final String UI_PATH_PARTNERS_EMAIL_ADDRESS = 'partnerops@uipath.com';
  public static final Integer EMAIL_REMINDER_INITIAL_WAITTIME = 7;
  public static final Integer EMAIL_REMINDER_ESCALATED_WAITTIME = 14;
  public static final String SALESFORCEBASEURL = Utilities_PP.getSalesforceBaseUrl();
  public static final User DEFAULT_USER = getDefaultToUser();

  public String sendVerificationCode(String recipientAddress) {
    final String verificationCode = Utilities_PP.getRandomNumbersAsString(5);
    final EmailTemplatesSelector_PP emailTemplatesSelector = (EmailTemplatesSelector_PP) Application_PP.Selector.newInstance(
      EmailTemplate.SObjectType
    );
    final EmailTemplate emailTemplate = emailTemplatesSelector.queryEmailTemplateByName(
      PARTNER_SELFREGISTRATION_VERIFICATION_CODE,
      false
    );

    //OrgWideEmailAddress sender = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'partnerportalsupport@uipath.com'];

    final Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    message.toAddresses = new List<String>{ recipientAddress };
    message.setSubject(emailTemplate.Subject);
    message.setPlainTextBody(emailTemplate.Body.replace('{!verificationCode}', verificationCode));
    //message.setOrgWideEmailAddressId(sender.Id);
    final List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>{ message };
    final List<Messaging.SendEmailResult> results;

    try {
      results = Messaging.sendEmail(messages);
    } catch (Exception e) {
      PartnerPortalException.LogException(
        e,
        'Sending out verification code',
        'Error while sending an email for verification'
      );
    }

    return (results[0].isSuccess()) ? (verificationCode) : '';
  }

  public void sendNotificationsForDraftDealRegistrations(List<DealRegistration__c> dealRegistrations) {
    final EmailTemplatesSelector_PP emailTemplatesSelector = (EmailTemplatesSelector_PP) Application_PP.Selector.newInstance(
      EmailTemplate.SObjectType
    );
    final EmailTemplate emailTemplate = emailTemplatesSelector.queryEmailTemplateByName(
      DEAL_REGISTRATION_DRAFT_NOTIFICATION,
      false
    );
    OrgWideEmailAddress sender = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'partners@uipath.com'];

    List<Id> ownerIds = Collection.of(dealRegistrations).pluckIds(DealRegistration__c.OwnerId);
    final UsersSelector_PP usersSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    Map<Id, User> users = (Map<Id, User>) Collection.of(usersSelector.selectById(new Set<Id>(ownerIds), false))
      .asMap(Map<Id, User>.class);

    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (DealRegistration__c dealRegistration : dealRegistrations) {
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      email.setTargetObjectId(users.get(dealRegistration.OwnerId).ContactId);
      email.setWhatId(dealRegistration.Id);
      email.setTemplateId(emailTemplate.Id);
      if (Utilities_CR.isScratchOrg()) {
        email.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
      } else {
        email.setOrgWideEmailAddressId(sender.Id);
      }
      email.setSaveAsActivity(false);
      email.setUseSignature(false);
      emails.add(email);
    }

    try {
      Messaging.sendEmail(emails, false);
    } catch (Exception e) {
      PartnerPortalException.LogException(
        e,
        'Sending out draft notification emails.',
        'Error while sending draft notification emails.'
      );
    }
  }

  public static void sendApplicationStatusChange(List<Partner_Application_Form__c> records) {
    String body =
      '<html><body>Hello user!' +
      '</br>' +
      '</br>This is a notification that the following Partner Application has been assigned to you and needs your review for approval or decline: ' +
      '</br>' +
      '</br>Partner Application Form: <a href="{RECORD_URL}">{RECORD_NAME}</a> ' +
      '</br>Company: {COMPANY}' +
      '</br>Lead: <a href="{LEAD_URL}">{LEAD_NAME}</a> ' +
      '</br>' +
      '</br>Thanks!' +
      '</body></html>';
    PartnerApplicationForms_PP formsDomain = (PartnerApplicationForms_PP) Application_PP.Domain.newInstance(
      records,
      Partner_Application_Form__c.SObjectType
    );

    Set<Id> leadIds = formsDomain.getLeadIds();
    LeadsSelector_PP leadsSelector = (LeadsSelector_PP) Application_PP.Selector.newInstance(Lead.SObjectType);
    Map<Id, Lead> leads = new Map<Id, Lead>(leadsSelector.selectById(leadIds, false));
    Leads_PP leadsDomain = (Leads_PP) Application_PP.Domain.newInstance(leads.values(), Lead.SObjectType);

    Map<Id, List<User>> leadOwnersByLeadIds = getLeadOwnersByLeadIds(leadsDomain);

    fflib_ISObjectUnitOfWork unitOfWork = Application.UnitOfWork.newInstance();

    for (Partner_Application_Form__c record : records) {
      Messaging.SingleEmailMessage message = createEmailMessageForRecord(
        body,
        record,
        leadOwnersByLeadIds,
        new Map<Id, User>(),
        leads
      );
      if (message != null)
        unitOfWork.registerEmail(message);
    }

    unitOfWork.commitWork();
  }

  public static void sendOpenFormReminder(List<Partner_Application_Form__c> records) {
    String body =
      '<html><body>Dear user!' +
      '</br>' +
      '</br>This is a reminder that the following Partner Application has been pending for {WAIT_TIME} days and needs your review for approval or decline: ' +
      '</br>' +
      '</br>Partner Application Form: <a href="{RECORD_URL}">{RECORD_NAME}</a> ' +
      '</br>Company: {COMPANY}' +
      '</br>Lead: <a href="{LEAD_URL}">{LEAD_NAME}</a> ' +
      '</br>' +
      '</br>Thanks!' +
      '</body></html>';
    UsersService_PP usersService = new UsersService_PP();
    PartnerApplicationForms_PP formsDomain = (PartnerApplicationForms_PP) Application_PP.Domain.newInstance(
      records,
      Partner_Application_Form__c.SObjectType
    );
    Map<Id, User> managers = usersService.getManagerByUserId(formsDomain.getOwnerIds());

    Set<Id> leadIds = formsDomain.getLeadIds();
    LeadsSelector_PP leadsSelector = (LeadsSelector_PP) Application_PP.Selector.newInstance(Lead.SObjectType);
    Map<Id, Lead> leads = new Map<Id, Lead>(leadsSelector.selectById(leadIds, false));
    Leads_PP leadsDomain = (Leads_PP) Application_PP.Domain.newInstance(leads.values(), Lead.SObjectType);

    Map<Id, List<User>> leadOwnersByLeadIds = getLeadOwnersByLeadIds(leadsDomain);

    Map<Id, User> leadOwnerManagers = usersService.getManagerByUserId(leadsDomain.getAllUserOwnerIds());
    managers.putAll(leadOwnerManagers); //userId and his manager

    fflib_ISObjectUnitOfWork unitOfWork = Application.UnitOfWork.newInstance();

    for (Partner_Application_Form__c record : records) {
      Messaging.SingleEmailMessage message = createEmailMessageForRecord(
        body,
        record,
        leadOwnersByLeadIds,
        managers,
        leads
      );
      if (message != null)
        unitOfWork.registerEmail(message);
    }

    unitOfWork.commitWork();
  }

  private static Map<Id, List<User>> getLeadOwnersByLeadIds(Leads_PP leadsDomain) {
    Map<Id, List<User>> leadOwnersByLeadIds = new Map<Id, List<User>>();

    Map<Id, User> leadOwnerByLeadIds = leadsDomain.getOwnerUserByLeadId();
    for (Id leadId : leadOwnerByLeadIds.keySet()) {
      List<User> listUsers = new List<User>{ leadOwnerByLeadIds.get(leadId) };
      leadOwnersByLeadIds.put(leadId, listUsers);
    }

    GroupsService_PP gService = new GroupsService_PP();
    Map<Id, Id> ownerGroupIdByLeadId = leadsDomain.getOwnerGroupIdByLeadId();
    Set<Id> uniqueGroupIds = new Set<Id>(ownerGroupIdByLeadId.values());
    Map<Id, List<User>> firstLevelUsersByGroupId = gService.getFirstLevelUsersByGroupId(uniqueGroupIds);
    for (Id leadId : ownerGroupIdByLeadId.keySet()) {
      Id leadOwnerGroupId = ownerGroupIdByLeadId.get(leadId);
      if (leadOwnersByLeadIds.get(leadId) == null) {
        leadOwnersByLeadIds.put(leadId, firstLevelUsersByGroupId.get(leadOwnerGroupId));
      } else {
        List<User> listUsers = leadOwnersByLeadIds.get(leadId);
        listUsers.addAll(firstLevelUsersByGroupId.get(leadOwnerGroupId));
        leadOwnersByLeadIds.put(leadId, listUsers);
      }
    }
    return leadOwnersByLeadIds;
  }

  private static Messaging.SingleEmailMessage createEmailMessageForRecord(
    String emailMessageHtmlBody,
    Partner_Application_Form__c record,
    Map<Id, List<User>> leadOwnersByLeadIds,
    Map<Id, User> managers,
    Map<Id, Lead> leads
  ) {
    //URL.getSalesforceBaseUrl().toExternalForm() does not work from the portal partner experience
    String recordUrl = SALESFORCEBASEURL + '/' + record.Id;
    String leadUrl = SALESFORCEBASEURL + '/' + record.Lead__c;

    if (record.Application_Status_Date__c == null)
      return null;
    Date appStatusDate = Date.newinstance(
      record.Application_Status_Date__c.year(),
      record.Application_Status_Date__c.month(),
      record.Application_Status_Date__c.day()
    );
    Integer waitTime = appStatusDate.daysBetween(System.today());
    if (waitTime > 0 && waitTime < EMAIL_REMINDER_INITIAL_WAITTIME)
      return null;

    Lead associatedLead = leads.get(record.Lead__c);
    if (associatedLead == null)
      return null;

    if (leadOwnersByLeadIds.get(record.Lead__c) == null || leadOwnersByLeadIds.get(record.Lead__c).size() <= 0)
      return null;

    String recordName = record.Full_Name__c == null ? String.valueOf(record.Id) : record.Full_Name__c;
    String leadName = associatedLead.Full_Name__c == null
      ? String.valueOf(record.Lead__c)
      : associatedLead.Full_Name__c;

    String body = emailMessageHtmlBody
      .replace('{RECORD_URL}', recordUrl)
      .replace('{RECORD_NAME}', recordName)
      .replace('{LEAD_URL}', leadUrl)
      .replace('{LEAD_NAME}', leadName)
      .replace('{WAIT_TIME}', String.valueOf(waitTime))
      .replace('{COMPANY}', associatedLead.Company);

    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    message.setSenderDisplayName('UIPath Partner Portal');
    message.setSubject('Open Partner Approval Form');
    message.setHtmlBody(body);

    return getMessageWithToAddress(
      message,
      leadOwnersByLeadIds.get(associatedLead.id),
      associatedLead,
      managers,
      waitTime
    );
  }

  private static Messaging.SingleEmailMessage getMessageWithToAddress(
    Messaging.SingleEmailMessage message,
    List<User> toUsers,
    Lead associatedLead,
    Map<Id, User> managers,
    Integer waitTime
  ) {
    Set<String> toIds = new Set<String>();
    Set<String> ccIds = new Set<String>();

    for (User u : toUsers) {
      toIds.add(u.Id);
      if (waitTime >= EMAIL_REMINDER_ESCALATED_WAITTIME && managers != null && managers.get(u.Id) != null) {
        ccIds.add(managers.get(u.Id).id);
      }
    }

    if (toIds != null) {
      message.setToAddresses(new List<String>(toIds));
    } else {
      message.setToAddresses(new List<String>{ DEFAULT_USER.id });
    }

    if (managers != null && ccIds != null)
      message.setCcAddresses(new List<String>(ccIds));

    return message;
  }

  private static User getDefaultToUser() {
    User defaultToUser = new User();
    UsersSelector_PP userSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    List<User> users = (List<User>) userSelector.selectByEmail(
      new Set<String>{ UI_PATH_PARTNERS_EMAIL_ADDRESS + '.invalid', UI_PATH_PARTNERS_EMAIL_ADDRESS },
      false
    );
    if (users.size() > 0) {
      defaultToUser = users[0];
    } else {
      defaultToUser = (User) userSelector.selectByEmail(new Set<String>{ System.UserInfo.getUserEmail() }, false)[0];
    }
    return defaultToUser;
  }
}