public without sharing class UsersService_PP {
  private static Boolean isSandbox {
    get {
      return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
  }

  public String login(String username, String password, String startUrl) {
    if (!username.endsWithIgnoreCase('.upc') && !isSandbox) {
      username = username + '.upc';
    }

    return Site.login(username, password, startUrl).getUrl();
  }

  public void forgotPassword(String username) {
    if (!username.endsWithIgnoreCase('.upc') && !isSandbox) {
      username = username + '.upc';
    }

    Site.forgotPassword(username);
  }

  public Id createPartnerUser(
    User partnerUser,
    String contactId,
    String accountId,
    String partnerProfileName,
    Boolean agreedToTermsAndConditions
  ) {
    return createPartnerUser(partnerUser, contactId, accountId, partnerProfileName, agreedToTermsAndConditions, null);
  }

  public Id createPartnerUser(
    User partnerUser,
    String contactId,
    String accountId,
    String partnerProfileName,
    Boolean agreedToTermsAndConditions,
    String password
  ) {
    final ProfilesSelector_PP profilesSelector = (ProfilesSelector_PP) Application_PP.Selector.newInstance(
      Profile.SObjectType
    );
    final Profile partnerProfile = profilesSelector.elevatedSelectByName(new Set<String>{ partnerProfileName })[0];

    final AccountsSelector_PP accountsSelector = (AccountsSelector_PP) Application_PP.Selector.newInstance(
      Account.SObjectType
    );
    final Account partnerAccount = accountsSelector.selectById(new Set<Id>{ accountId }, false)[0];

    Contact partnerContact;
    if (String.isNotBlank(contactId)) {
      final ContactsSelector_PP contactsSelector = (ContactsSelector_PP) Application_PP.Selector.newInstance(
        Contact.SObjectType
      );
      partnerContact = contactsSelector.selectById(new Set<Id>{ contactId }, false)[0];
    }

    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    if (partnerContact != null) {
      if (!partnerContact.AccountId.equals(accountId)) {
        partnerContact.AccountId = accountId;
        partnerContact.OwnerId = partnerAccount.OwnerId;

        unitOfWork.registerDirty(partnerContact);
      }
    } else {
      LeadsSelector_PP leadsSelector = (LeadsSelector_PP) Application_PP.Selector.newInstance(Lead.SObjectType);

      List<Lead> leads = leadsSelector.selectByEmailNotConverted(new Set<String>{ partnerUser.Email }, false);

      if (!leads.isEmpty()) {
        LeadsService_PP leadsService = (LeadsService_PP) Application_PP.Service.newInstance(LeadsService_PP.class);

        Database.LeadConvertResult leadConvertResult = leadsService.convertPartnerUserLead(
          leads.get(0),
          partnerUser,
          partnerAccount
        );

        if (leadConvertResult.isSuccess()) {
          partnerContact = new Contact(Id = leadConvertResult.getContactId());
        }
      }

      if (partnerContact == null) {
        partnerContact = new Contact(
          AccountId = accountId,
          Email = partnerUser.Email,
          FirstName = partnerUser.Firstname,
          LastName = partnerUser.Lastname,
          MailingCountry = partnerUser.Country,
          OwnerId = partnerAccount.OwnerId,
          Department__c = 'Other'
        );

        unitOfWork.registerNew(partnerContact);
      }
    }
    String nickname = partnerUser.CommunityNickname;
    if (nickname.length() > 40) {
      nickname = nickname.subString(0, 40);
    }

    final User actualPartnerUser = new User(
      AgreedtoPartnerCommPrivacyPolicy__c = agreedToTermsAndConditions,
      AgreedtoPartnerCommTermsofUse__c = agreedToTermsAndConditions,
      CommunityNickname = nickname,
      ContactId = partnerContact.Id,
      Country = partnerUser.Country,
      Email = partnerUser.Email,
      FirstName = partnerUser.Firstname,
      LanguageLocaleKey = 'en_US',
      LastName = partnerUser.Lastname,
      ProfileId = partnerProfile.Id,
      UserName = partnerUser.UserName + '.upc'
    );

    unitOfWork.commitWork();

    if (password != null) {
      return Site.createExternalUser(actualPartnerUser, partnerAccount.Id, password);
    } else {
      return Site.createExternalUser(actualPartnerUser, partnerAccount.Id);
    }
  }

  public void deactivateUsers(List<User> users) {
    fflib_ISObjectUnitOfWork unitOfWork = Application_PP.UnitOfWork.newInstance();

    for (User user : users) {
      user.isActive = false;
      unitOfWork.registerDirty(user);
    }
    unitOfWork.commitWork();
  }

  public Map<Id, User> getManagerByUserId(Set<Id> users) {
    UsersSelector_PP usersSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    Users_PP usersDomain = (Users_PP) Application_PP.Domain.newInstance(
      usersSelector.selectById(users, false),
      User.SObjectType
    );
    Map<Id, User> managers = new Map<Id, User>(usersSelector.selectById(usersDomain.getManagerIds(), false));

    Map<Id, User> managersByUserId = new Map<Id, User>();
    for (sObject record : usersDomain.getRecords()) {
      User usr = (User) record;
      if (usr.ManagerId != null && managers.get(usr.ManagerId) != null) {
        managersByUserId.put(usr.Id, managers.get(usr.ManagerId));
      }
    }
    return managersByUserId;
  }
}