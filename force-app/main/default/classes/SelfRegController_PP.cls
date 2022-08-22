public without sharing class SelfRegController_PP {
  @AuraEnabled(cacheable=true)
  public static Map<String, List<Object>> getSelfRegData(String email) {
    final Map<String, List<Object>> selfRegData = new Map<String, List<Object>>{};

    final String emailAddress = (String.isBlank(email) ? '' : email.trim());
    if (isInValidEmail(emailAddress)) {
      selfRegData.put(
        'Error',
        new List<UserErrorObject>{ new UserErrorObject('Email address incorrectly formatted', '', null) }
      );
      return selfRegData;
    }

    final UsersSelector_PP usersSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    final List<User> partnerUsers = usersSelector.selectByEmail(new Set<String>{ emailAddress }, false);

    if (partnerUsers.isEmpty()) {
      final ContactsSelector_PP contactsSelector = (ContactsSelector_PP) Application_PP.Selector.newInstance(
        Contact.SObjectType
      );
      final List<Contact> partnerContacts = contactsSelector.selectByEmail(new Set<String>{ emailAddress }, false);
      final Contact partnerContact = (partnerContacts.isEmpty()) ? null : partnerContacts[0];

      AccountsService_PP accountsService = ((AccountsService_PP) Application_PP.Service.newInstance(
        AccountsService_PP.class
      ));
      final Set<Id> accountIds = accountsService.getAccountIdsForSelfReg(partnerContact, emailAddress);

      final AccountsSelector_PP accountsSelector = (AccountsSelector_PP) Application_PP.Selector.newInstance(
        Account.SObjectType
      );
      final List<Account> accounts = accountsSelector.selectById(accountIds, false);

      selfRegData.put('Contacts', partnerContacts);
      selfRegData.put('Accounts', accounts);

      return selfRegData;
    }

    selfRegData.put(
      'Error',
      new List<UserErrorObject>{ new UserErrorObject('User already exists!', '', partnerUsers[0].isActive) }
    );
    return selfRegData;
  }

  @AuraEnabled(cacheable=false)
  public static String sendVerificationCode(String workEmail) {
    final String emailAddress = (String.isBlank(workEmail) ? '' : workEmail.trim());
    if (isInValidEmail(emailAddress))
      throw new AuraHandledException('Invalid formatted email address');
    try {
      EmailsService_PP emailsService = ((EmailsService_PP) Application_PP.Service.newInstance(EmailsService_PP.class));
      return emailsService.sendVerificationCode(emailAddress);
    } catch (Exception e) {
      PartnerPortalException.LogException(
        e,
        'Self Registration Process',
        ('Error while sending verification code to the following Email Address' + workEmail)
      );
      return '';
    }
  }

  @AuraEnabled
  public static Boolean createPartner(
    String contactId,
    String accountId,
    String firstname,
    String country,
    Boolean isContentUser,
    String lastname,
    String workEmail
  ) {
    return createPartner(contactId, accountId, firstname, country, isContentUser, lastname, workEmail, null);
  }

  @AuraEnabled
  public static Boolean createPartner(
    String contactId,
    String accountId,
    String firstname,
    String country,
    Boolean isContentUser,
    String lastname,
    String workEmail,
    String password
  ) {
    final String emailAddress = (String.isBlank(workEmail) ? '' : workEmail.trim());

    final String partnerProfileName = (isContentUser)
      ? System.Label.UiPath_Partner_Comm_Content_User_Profile_Name
      : System.Label.UiPath_Partner_Comm_User_Profile_Name;

    final User partnerUser = new User(
      FirstName = firstname,
      LastName = lastname,
      UserName = emailAddress,
      Email = emailAddress,
      EmailEncodingKey = 'UTF-8',
      Country = country,
      CommunityNickname = emailAddress
    );

    try {
      if (isInValidEmail(emailAddress))
        throw new AuraHandledException('Invalid formatted email address');

      UsersService_PP usersService = ((UsersService_PP) Application_PP.Service.newInstance(UsersService_PP.class));
      usersService.createPartnerUser(partnerUser, contactId, accountId, partnerProfileName, true, password);
      return true;
    } catch (Exception e) {
      PartnerPortalException.LogException(
        e,
        'Self Registration Process',
        String.format(
          'Error while creating User with the following Details:\nFirstname: {0}\nLastname: {1}\nEmail: {2}\nContact Id: {3}\nAccount Id: {4}',
          new List<Object>{ firstname, lastname, workEmail, contactId, accountId }
        )
      );

      return false;
    }
  }

  public static Boolean isInValidEmail(String emailAddress) {
    String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,63}|[0-9]{1,3})';
    Pattern emailPattern = Pattern.compile(emailRegex);
    Matcher matcher = emailPattern.matcher(emailAddress);
    return !matcher.matches();
  }

  public class UserErrorObject {
    @AuraEnabled
    public String message { get; set; }
    @AuraEnabled
    public String additionalInfo { get; set; }
    @AuraEnabled
    public Boolean isActive { get; set; }

    public UserErrorObject(String message, String additionalInfo, Boolean isActive) {
      this.message = message;
      this.additionalInfo = additionalInfo;
      this.isActive = isActive;
    }
  }
}