public with sharing class PartnerApprovalController_PP {
  @InvocableMethod(
    Label='Approve Partner Application Form'
    Description='This process approves a partner application form and activates the given forms as partner'
  )
  public static void approvePartnerApplication(List<approvePartnerApplicationRequest> requests) {
    try {
      approvePartnerApplicationRequest request = getRequest(requests);
      Partner_Application_Form__c form = getPartnerApplicationForm(request);
      Database.LeadConvertResult lcr = convertLead(request, form);
      if (hasSeparateSignatoryContact(form)) {
        Contact authorizedSignatoryContact = createSignatoryContact(form, lcr);
        form.Authorized_Signatory_Contact__c = authorizedSignatoryContact.Id;
      }
      //add contact and account Id on the form record
      form.Account__c = lcr.getAccountId();
      form.Contact__c = lcr.getContactId();
      update form;

      //set correct record type to the account
      AccountsService_PP.updateAccountRtypeANDPaf(
        new Set<Id>{ lcr.getAccountId() },
        AccountsService_PP.PARTNER_RT,
        form.Id
      );
    } catch (Exception e) {
      throw new PartnerApprovalException(e.getMessage());
    }
  }

  private static Database.LeadConvertResult convertLead(
    approvePartnerApplicationRequest request,
    Partner_Application_Form__c form
  ) {
    Database.LeadConvert leadConvert = new Database.LeadConvert();
    leadConvert.setLeadId(form.Lead__c);
    leadConvert.setConvertedStatus(getLeadStatus().MasterLabel);
    leadConvert.setDoNotCreateOpportunity(true);

    if (request.getAccountId() != null) {
      leadConvert.setAccountId(request.getAccountId());
    }

    if (request.getContactId() != null) {
      leadConvert.setContactId(request.getContactId());
    }

    Database.LeadConvertResult lcr = Database.convertLead(leadConvert);
    System.assert(lcr.isSuccess());
    return lcr;
  }

  private static Contact createSignatoryContact(Partner_Application_Form__c form, Database.LeadConvertResult lcr) {
    Contact contact = new Contact(
      LastName = form.Authorized_Signatory_Name__c,
      Title = form.Authorized_Signatory_Title__c,
      Email = form.Authorized_Signatory_Email__c,
      Phone = form.Authorized_Signatory_Phone__c,
      LeadSource = 'Partner',
      AccountId = lcr.getAccountId(),
      Role__c = 'Authorised Signatory',
      Department__c = 'Other',
      RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact').getRecordTypeId()
    );
    System.debug(contact);
    insert contact;
    return contact;
  }

  private static LeadStatus getLeadStatus() {
    List<LeadStatus> leadStatuses = [SELECT Id, MasterLabel FROM LeadStatus WHERE MasterLabel = 'Qualified' LIMIT 1];
    LeadStatus leadStatus = (leadStatuses.size() == 1) ? leadStatuses.get(0) : null;
    return leadStatus;
  }

  private static Partner_Application_Form__c getPartnerApplicationForm(approvePartnerApplicationRequest request) {
    List<Partner_Application_Form__c> forms = ((PartnerApplicationFormsSelector_PP) Application_PP.Selector.newInstance(
        Partner_Application_Form__c.SObjectType
      ))
      .selectById(new Set<Id>{ request.partnerApplicationFormId }, false);
    return (forms.size() == 1) ? forms.get(0) : null;
  }

  private static approvePartnerApplicationRequest getRequest(List<approvePartnerApplicationRequest> requests) {
    return requests.get(0);
  }

  private static Boolean hasSeparateSignatoryContact(Partner_Application_Form__c form) {
    return String.isNotBlank(form.Authorized_Signatory_Email__c) &&
      String.isNotBlank(form.Authorized_Signatory_Phone__c) &&
      ((form.Authorized_Signatory_Phone__c != form.Phone__c) || (form.Authorized_Signatory_Email__c != form.Email__c));
  }

  public class approvePartnerApplicationRequest {
    @InvocableVariable(
      Label='Partner Application Form Id'
      Description='The Id of the Partner_Application_Form__c record'
      Required=true
    )
    public Id partnerApplicationFormId;

    @InvocableVariable(Label='Account Id to use' Description='The Id of an existing account record' Required=false)
    public String accountId;

    @InvocableVariable(Label='Contact Id to use' Description='The Id of an existing account record' Required=false)
    public String contactId;

    public Id getAccountId() {
      if (String.isBlank(accountId))
        return null;

      return (Id) accountId;
    }

    public Id getContactId() {
      if (String.isBlank(contactId))
        return null;

      return (Id) contactId;
    }
  }

  public class PartnerApprovalException extends Exception {
  }
}