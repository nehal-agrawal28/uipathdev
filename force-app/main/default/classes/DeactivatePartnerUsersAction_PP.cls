public with sharing class DeactivatePartnerUsersAction_PP extends AbstractQueueable {
  private List<User> m_Users;
  private String m_PartnerAccountId;
  private Set<String> m_PartnerUserProfiles = new Set<String>{
    System.Label.UiPath_Partner_Comm_Admin_Profile_Name,
    System.Label.UiPath_Partner_Comm_Content_User_Profile_Name,
    System.Label.UiPath_Partner_Comm_Manager_Profile_Name,
    System.Label.UiPath_Partner_Comm_User_Profile_Name
  };

  public DeactivatePartnerUsersAction_PP(List<User> users) {
    super('DeactivatePartnerUsersAction_PP');
    m_Users = users;
  }

  public DeactivatePartnerUsersAction_PP(String accountId) {
    super('DeactivatePartnerUsersAction_PP');
    m_PartnerAccountId = accountId;
  }

  public override void work() {
    if (m_PartnerAccountId == null)
      return;

    final ContactsSelector_PP contactsSelector = (ContactsSelector_PP) Application_PP.Selector.newInstance(
      Contact.SObjectType
    );
    List<Contact> contacts = contactsSelector.selectByAccountId(new Set<Id>{ m_PartnerAccountId }, true);
    final Set<Id> contactIds = Utilities_PP.pluckIdField(contacts, Contact.Id);

    final UsersSelector_PP usersSelector = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    m_Users = usersSelector.selectByContactIdAndProfileName(contactIds, m_PartnerUserProfiles, true);

    try {
      UsersService_PP usersService = ((UsersService_PP) Application_PP.Service.newInstance(UsersService_PP.class));
      usersService.deactivateUsers(m_Users);
    } catch (Exception e) {
      PartnerPortalException.LogException(
        e,
        'Deactivate Partner User Process',
        'Error while deactivating Partner Users'
      );
    }
  }
}