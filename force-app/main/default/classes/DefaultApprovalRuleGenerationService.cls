/**
 * Default Implementation for interface IApprovalRuleGenerationService
 * @author Girish Lakshmanan
 * @date 23/08/2019
 *
 */
public with sharing class DefaultApprovalRuleGenerationService implements IApprovalRuleGenerationService {
  private TransactionManager transactionManager;

  public List<Id> generate(List<Id> matrixRecordIds) {
    transactionManager = getNewTransactionManager();

    ApprovalRuleServiceFactory.ApprovalRuleFactory approvalRuleFactory = new ApprovalRuleServiceFactory.ApprovalRuleFactory(
      transactionManager,
      new DefaultApprovalMatrixRuleMapper()
    );
    ApprovalMatrix matrix = ApprovalMatrix.newInstanceFor(
      matrixRecordIds,
      Schema.SObjectType.ApprovalRuleMatrix__c.fieldSets.ConditionsMapFields
    );
    matrix.generate(approvalRuleFactory);
    transactionManager.commitWork();

    //Start a new Transaction because we need the Ids hydrated
    transactionManager = getNewTransactionManager();

    List<String> hashesList = getHashesList(matrixRecordIds);
    deleteStaleConditions(hashesList);
    updateConditionsTypeOnApprovalRule(hashesList);

    transactionManager.commitWork();

    return getGeneratedRuleIds(approvalRuleFactory);
  }

  private TransactionManager getNewTransactionManager() {
    return new TransactionManager(
      new List<SObjectType>{ sbaa__ApprovalRule__c.SObjectType, sbaa__ApprovalCondition__c.SObjectType }
    );
  }

  /**
   * This is done separately because of validation rules
   *
   * @param hashesList
   */
  private void updateConditionsTypeOnApprovalRule(List<String> hashesList) {
    List<sbaa__ApprovalRule__c> approvalRules = [
      SELECT Id, MatrixMD5Hash__c
      FROM sbaa__ApprovalRule__c
      WHERE MatrixMD5Hash__c IN :hashesList
    ];

    for (sbaa__ApprovalRule__c approvalRule : approvalRules) {
      approvalRule.sbaa__ConditionsMet__c = 'Custom';
    }
    transactionManager.registerDirty(approvalRules);
  }

  private List<Id> getGeneratedRuleIds(ApprovalRuleServiceFactory.ApprovalRuleFactory approvalRuleFactory) {
    List<Id> ruleIds = new List<Id>();
    for (sbaa__ApprovalRule__c rule : approvalRuleFactory.approvalRules)
      ruleIds.add(rule.Id);
    return ruleIds;
  }

  private void deleteStaleConditions(List<String> hashesList) {
    transactionManager.registerDeleted(
      [
        SELECT Id
        FROM sbaa__ApprovalCondition__c
        WHERE MatrixMD5Hash__c NOT IN :hashesList AND sbaa__ApprovalRule__r.MatrixMD5Hash__c IN :hashesList
      ]
    );
  }

  private List<String> getHashesList(List<Id> matrixRecordIds) {
    List<ApprovalRuleMatrix__c> MD5hashes = [
      SELECT Id, MD5Hash__c
      FROM ApprovalRuleMatrix__c
      WHERE Id IN :matrixRecordIds
    ];
    List<String> hashesList = new List<String>();
    for (ApprovalRuleMatrix__c approvalRuleMatrix : MD5hashes) {
      hashesList.add(approvalRuleMatrix.MD5Hash__c);
    }
    return hashesList;
  }
}