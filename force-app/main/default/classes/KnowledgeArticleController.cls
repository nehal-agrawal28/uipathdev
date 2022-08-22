public with sharing class KnowledgeArticleController {
  @AuraEnabled
  public static KnowledgeWrapper getFieldMetadata(String caseId) {
    List<String> permissionSetNames = new List<String>{
      'Knowledge_Creator',
      'Knowledge_Technical_Reviewer',
      'Knowledge_Quality_Coach'
    };

    KnowledgeWrapper wrapper = new KnowledgeWrapper();
    List<PermissionSetAssignment> permissionSets = [
      SELECT Id, AssigneeId
      FROM PermissionSetAssignment
      WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name IN :permissionSetNames
    ];
    wrapper.isCreateable = permissionSets != null && !permissionSets.isEmpty();
    wrapper.userId = UserInfo.getUserId();
    if (wrapper.isCreateable) {
      wrapper.studioVersions = new Map<String, String>();
      wrapper.orchestratorVersions = new Map<String, String>();
      wrapper.productComponentPicklistMappings = new Map<String, String>();
      List<Schema.PicklistEntry> studiople = Knowledge__kav.Studio_Version__c.getDescribe().getPicklistValues();
      List<Schema.PicklistEntry> orcple = Knowledge__kav.Orchestrator_Version__c.getDescribe().getPicklistValues();
      List<Schema.PicklistEntry> prodCompPle = Case.Related_To__c.getDescribe().getPicklistValues();
      for (Schema.PicklistEntry s : studiople) {
        wrapper.studioVersions.put(s.getValue(), s.getLabel());
      }
      for (Schema.PicklistEntry o : orcple) {
        wrapper.orchestratorVersions.put(o.getValue(), o.getLabel());
      }
      for (Schema.PicklistEntry p : prodCompPle) {
        wrapper.productComponentPicklistMappings.put(p.getValue(), p.getLabel());
      }
      wrapper.prodCompAndSubCompValues = DependentPickListUtil.getDependentMap(
        new Knowledge__kav(),
        'Product_Component__c',
        'Sub_Component__c'
      );
      wrapper.prodCompAndVersionValues = DependentPickListUtil.getDependentMap(
        new Knowledge__kav(),
        'Product_Component__c',
        'Product_Component_Version__c'
      );
      if (String.isNotBlank(caseId) && String.isNotEmpty(caseId)) {
        wrapper.caseObj = [
          SELECT
            Id,
            Solution__c,
            Problem__c,
            Cause__c,
            Related_To__c,
            Sub_Component__c,
            Studio_Version__c,
            Orchestrator_Version__c,
            Product_Component_Version__c
          FROM Case
          WHERE id = :caseId
        ];
      }
    }
    return wrapper;
  }

  @AuraEnabled
  public static String createKnowledgeArticle(Knowledge__kav knowledgeObj) {
    insert knowledgeObj;
    return knowledgeObj.Id;
  }

  @AuraEnabled
  public static String updateKnowledgeArticle(Knowledge__kav knowledgeObj) {
    update knowledgeObj;
    return knowledgeObj.Id;
  }

  @AuraEnabled
  public static KnowledgeReviewerWrapper getReviewerData(String recordId) {
    Knowledge__kav record = [SELECT Id, CreatedById FROM Knowledge__kav WHERE Id = :recordId];
    KnowledgeReviewerWrapper wrapper = new KnowledgeReviewerWrapper();
    wrapper.userId = UserInfo.getUserId();
    Map<Id, User> qualityReviewers = new Map<Id, User>(
      [
        SELECT Id, Name, Email, IsActive
        FROM User
        WHERE
          IsActive = TRUE
          AND Id IN (SELECT UserOrGroupid FROM GroupMember WHERE Group.Name = 'KB Quality Reviewers')
      ]
    );
    List<User> technicalReviewers = new List<User>();
    for (User technicalReviewer : [
      SELECT Id, Name, Email, IsActive
      FROM User
      WHERE
        IsActive = TRUE
        AND Id IN (SELECT UserOrGroupid FROM GroupMember WHERE Group.Name = 'KB Technical Reviewers')
    ]) {
      if (qualityReviewers.containsKey(technicalReviewer.Id) || technicalReviewer.Id != record.CreatedById) {
        technicalReviewers.add(technicalReviewer);
      }
    }

    wrapper.technicalReviewers = technicalReviewers;
    wrapper.qualityReviewers = qualityReviewers.values();

    return wrapper;
  }

  @AuraEnabled
  public static boolean publishKnowledgeArticle(String recordId, String articleId) {
    try {
      KbManagement.PublishingService.publishArticle(articleId, true);
      return true;
    } catch (Exception e) {
      System.debug('exception - ' + e.getMessage() + ' line number' + e.getLineNumber());
      return false;
    }
  }

  @AuraEnabled
  public static boolean publishTranslation(String recordId) {
    try {
      Knowledge__kav knowledgeRecord = new Knowledge__kav(Id = recordId, Translation_Status__c = 'Published');
      update knowledgeRecord;
      KbManagement.PublishingService.completeTranslation(recordId);
      return true;
    } catch (Exception e) {
      System.debug('exception - ' + e.getMessage() + ' line number' + e.getLineNumber());
      return false;
    }
  }

  @AuraEnabled
  public static KnowledgeWrapper getTranslationsData() {
    List<String> permissionSetNames = new List<String>{
      'Knowledge_Creator',
      'Knowledge_Technical_Reviewer',
      'Knowledge_Quality_Coach'
    };

    KnowledgeWrapper wrapper = new KnowledgeWrapper();
    List<PermissionSetAssignment> permissionSets = [
      SELECT Id, AssigneeId
      FROM PermissionSetAssignment
      WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name IN :permissionSetNames
    ];
    wrapper.isCreateable = permissionSets != null && !permissionSets.isEmpty();
    wrapper.userId = UserInfo.getUserId();
    wrapper.translationReviewers = [
      SELECT Id, Name, Email, isActive
      FROM user
      WHERE isActive = TRUE AND id IN (SELECT userorgroupid FROM groupmember WHERE group.name = 'KB Quality Reviewers')
    ];
    return wrapper;
  }
  public class KnowledgeWrapper {
    @AuraEnabled
    public String userId { get; set; }
    @AuraEnabled
    public Boolean isCreateable { get; set; }
    @AuraEnabled
    public Map<String, String> studioVersions { get; set; }
    @AuraEnabled
    public Map<String, String> orchestratorVersions { get; set; }
    @AuraEnabled
    public Map<String, List<String>> prodCompAndSubCompValues { get; set; }
    @AuraEnabled
    public Map<String, List<String>> prodCompAndVersionValues { get; set; }
    @AuraEnabled
    public Case caseObj { get; set; }
    @AuraEnabled
    public Map<String, String> productComponentPicklistMappings { get; set; }
    @AuraEnabled
    public List<User> translationReviewers { get; set; }
  }
  public class KnowledgeReviewerWrapper {
    @AuraEnabled
    public String userId { get; set; }
    @AuraEnabled
    public List<User> technicalReviewers { get; set; }
    @AuraEnabled
    public List<User> qualityReviewers { get; set; }
  }
}