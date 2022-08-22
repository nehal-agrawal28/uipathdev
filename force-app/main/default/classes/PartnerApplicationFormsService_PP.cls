public without sharing class PartnerApplicationFormsService_PP {
  public static void shareWithDistributors(List<Partner_Application_Form__c> forms) {
    Map<String, List<Partner_Application_Form__c>> formsByCountry = buildFormsByCountry(forms);

    Map<Id, Set<String>> countriesByAccountId = DistributorConfigurationsService_PP.buildCountriesByAccountId(
      formsByCountry.keySet()
    );

    UsersSelector_PP usersSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);

    List<User> users = usersSelector.selectByAccountIds(countriesByAccountId.keySet(), false);

    List<Partner_Application_Form__Share> shares = new List<Partner_Application_Form__Share>();

    for (User user : users) {
      Set<String> countries = countriesByAccountId.get(user.AccountId);

      for (String country : countries) {
        List<Partner_Application_Form__c> countryForms = formsByCountry.get(country);

        for (Partner_Application_Form__c countryForm : countryForms) {
          shares.add(
            new Partner_Application_Form__Share(
              ParentId = countryForm.Id,
              UserOrGroupId = user.Id,
              AccessLevel = 'Read'
            )
          );
        }
      }
    }

    List<Database.SaveResult> results = Database.insert(shares, false);
  }

  public static Map<String, List<Partner_Application_Form__c>> buildFormsByCountry(
    List<Partner_Application_Form__c> forms
  ) {
    Map<String, List<Partner_Application_Form__c>> formsByCountry = new Map<String, List<Partner_Application_Form__c>>();

    for (Partner_Application_Form__c form : forms) {
      if (String.isBlank(form.Country__c))
        continue;

      String country = form.Country__c.toUpperCase();

      if (!formsByCountry.containsKey(country)) {
        formsByCountry.put(country, new List<Partner_Application_Form__c>());
      }

      formsByCountry.get(country).add(form);
    }

    return formsByCountry;
  }

  @future
  public static void aSyncConvertLeadForPAFs(Set<Id> recordIds) {
    ((PartnerApplicationFormsService_PP) Application_PP.Service.newInstance(PartnerApplicationFormsService_PP.class))
      .convertLeadForPAFs(recordIds);
  }

  public void convertLeadForPAFs(Set<Id> recordIds) {
    PartnerApplicationFormsSelector_PP selector = (PartnerApplicationFormsSelector_PP) Application_PP.Selector.newInstance(
      Partner_Application_Form__c.SObjectType
    );
    List<Partner_Application_Form__c> records = selector.selectById(recordIds, false);
    List<PartnerApprovalController_PP.approvePartnerApplicationRequest> requests = new List<PartnerApprovalController_PP.approvePartnerApplicationRequest>();

    for (Partner_Application_Form__c record : records) {
      if (record.UiPath_Compliance_Status__c == 'Approved') {
        PartnerApprovalController_PP.approvePartnerApplicationRequest request = new PartnerApprovalController_PP.approvePartnerApplicationRequest();
        request.accountId = record.Account__c;
        request.contactId = record.Contact__c;
        request.partnerApplicationFormId = record.Id;
        requests.add(request);
        PartnerApprovalController_PP.approvePartnerApplication(requests);
      }
    }
  }
}