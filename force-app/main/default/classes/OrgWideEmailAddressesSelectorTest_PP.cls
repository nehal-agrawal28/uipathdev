@IsTest
private class OrgWideEmailAddressesSelectorTest_PP {
  @IsTest
  static void itShouldSelectById() {
    // given
    List<OrgWideEmailAddress> orgEmails = [SELECT Id, Address FROM OrgWideEmailAddress];

    if (Utilities_CR.isScratchOrg()) {
      // don't assert if the list is empty. org wide email addresses don't currently work in scratch orgs
    } else {
      System.assertEquals(false, orgEmails.isEmpty());

      Set<Id> ids = new Set<Id>{ orgEmails.get(0).Id };

      OrgWideEmailAddressesSelector_PP selector = (OrgWideEmailAddressesSelector_PP) Application_PP.Selector.newInstance(
        OrgWideEmailAddress.SObjectType
      );

      // when
      List<OrgWideEmailAddress> orgEmailsWithSharing = selector.selectById(ids, true);
      List<OrgWideEmailAddress> orgEmailsWithoutSharing = selector.selectById(ids, false);

      // then
      System.assertEquals(false, orgEmailsWithSharing.isEmpty());
      System.assertEquals(false, orgEmailsWithoutSharing.isEmpty());
    }
  }

  @IsTest
  static void itShouldSelectByAddresses() {
    // given
    List<OrgWideEmailAddress> orgEmails = [SELECT Id, Address FROM OrgWideEmailAddress];
    if (Utilities_CR.isScratchOrg()) {
      // don't assert if the list is empty. org wide email addresses don't currently work in scratch orgs
    } else {
      System.assertEquals(false, orgEmails.isEmpty());

      Set<String> emails = new Set<String>{ orgEmails.get(0).Address };

      OrgWideEmailAddressesSelector_PP selector = (OrgWideEmailAddressesSelector_PP) Application_PP.Selector.newInstance(
        OrgWideEmailAddress.SObjectType
      );

      // when
      List<OrgWideEmailAddress> orgEmailsWithSharing = selector.selectByAddresses(emails, true);
      List<OrgWideEmailAddress> orgEmailsWithoutSharing = selector.selectByAddresses(emails, false);

      // then
      System.assertEquals(false, orgEmailsWithSharing.isEmpty());
      System.assertEquals(false, orgEmailsWithoutSharing.isEmpty());
    }
  }
}