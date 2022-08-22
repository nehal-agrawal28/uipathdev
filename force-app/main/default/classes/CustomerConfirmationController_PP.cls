public with sharing class CustomerConfirmationController_PP {
  public final Account Account { get; set; }

  public CustomerConfirmationController_PP() {
    UsersSelector_PP usersSelectorPP = (UsersSelector_PP) Application_PP.Selector.newInstance(User.SObjectType);
    ContactsSelector_PP contactsSelectorPP = (ContactsSelector_PP) Application_PP.Selector.newInstance(
      Contact.SObjectType
    );

    List<Contact> returnedContacts = contactsSelectorPP.selectById(
      new Set<Id>{ usersSelectorPP.selectById(new Set<Id>{ UserInfo.getUserId() }, false).get(0).ContactId },
      false
    );

    if (!returnedContacts.isEmpty()) {
      AccountsSelector_PP accountsSelector = (AccountsSelector_PP) Application_PP.Selector.newInstance(
        Schema.Account.SObjectType
      );
      Account = accountsSelector.selectById(new Set<Id>{ returnedContacts.get(0).AccountId }, false).get(0);
    }
  }
}