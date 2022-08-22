public without sharing class EmailTemplatesSelector_PP extends fflib_SObjectSelector {
  public List<Schema.SObjectField> getSObjectFieldList() {
    return new List<Schema.SObjectField>{ EmailTemplate.Subject, EmailTemplate.Body, EmailTemplate.DeveloperName };
  }

  public Schema.SObjectType getSObjectType() {
    return EmailTemplate.sObjectType;
  }

  public List<EmailTemplate> selectById(Set<Id> ids, Boolean withSharing) {
    if (withSharing) {
      return (List<EmailTemplate>) selectSObjectsById(ids);
    } else {
      return (List<EmailTemplate>) Database.query(
        newQueryFactory(false, false, true).setCondition('Id IN :ids').toSOQL()
      );
    }
  }

  public EmailTemplate queryEmailTemplateByName(String developerName, Boolean withSharing) {
    if (withSharing) {
      return (EmailTemplate) Database.query(
        newQueryFactory(true, true, true).setCondition('DeveloperName = :developerName').setLimit(1).toSOQL()
      );
    } else {
      return (EmailTemplate) Database.query(
        newQueryFactory(false, false, true).setCondition('DeveloperName = :developerName').setLimit(1).toSOQL()
      );
    }
  }

  public List<EmailTemplate> selectByDeveloperNames(Set<String> developerNames, Boolean withSharing) {
    if (withSharing) {
      return (List<EmailTemplate>) Database.query(
        newQueryFactory(true, true, true).setCondition('DeveloperName IN :developerNames').toSOQL()
      );
    } else {
      return (List<EmailTemplate>) Database.query(
        newQueryFactory(false, false, true).setCondition('DeveloperName IN :developerNames').toSOQL()
      );
    }
  }
}