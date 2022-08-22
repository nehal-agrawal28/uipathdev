@IsTest
private class EmailTemplatesSelectorTest_PP {
  @IsTest
  static void itShouldSelectById() {
    // given
    List<EmailTemplate> emailTemplates = [SELECT Id, DeveloperName FROM EmailTemplate];

    System.assertEquals(false, emailTemplates.isEmpty());

    Set<Id> ids = new Set<Id>{ emailTemplates.get(0).Id };

    EmailTemplatesSelector_PP selector = (EmailTemplatesSelector_PP) Application_PP.Selector.newInstance(
      EmailTemplate.SObjectType
    );

    // when
    List<EmailTemplate> emailTemplatesWithSharing = selector.selectById(ids, true);
    List<EmailTemplate> emailTemplatesWithoutSharing = selector.selectById(ids, false);

    // then
    System.assertEquals(false, emailTemplatesWithSharing.isEmpty());
    System.assertEquals(false, emailTemplatesWithoutSharing.isEmpty());
  }

  @IsTest
  static void itShouldSelectByDeveloperNames() {
    // given
    List<EmailTemplate> emailTemplates = [SELECT Id, DeveloperName FROM EmailTemplate];

    System.assertEquals(false, emailTemplates.isEmpty());

    Set<String> developerNames = new Set<String>{ emailTemplates.get(0).DeveloperName };

    EmailTemplatesSelector_PP selector = (EmailTemplatesSelector_PP) Application_PP.Selector.newInstance(
      EmailTemplate.SObjectType
    );

    // when
    List<EmailTemplate> emailTemplatesWithSharing = selector.selectByDeveloperNames(developerNames, true);
    List<EmailTemplate> emailTemplatesWithoutSharing = selector.selectByDeveloperNames(developerNames, false);

    // then
    System.assertEquals(false, emailTemplatesWithSharing.isEmpty());
    System.assertEquals(false, emailTemplatesWithoutSharing.isEmpty());
  }
}