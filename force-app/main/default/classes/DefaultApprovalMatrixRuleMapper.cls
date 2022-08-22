/**
 *Converts a single matrix record to a single Approval rule.
 * Only supports the ALL condition type
 * Does not do any DML; Lets the caller perform DML as appropriate
 * Expects Migration_ID__c to be populated in the input Matrix record. If not conditions will not map to parent rule and DML will fail;* 1.0 Girish Lakshmanan 23/08/2019 Initial Version
 *
 * @author Girish Lakshmanan
 * @date 23/08/2019
 *
 */

public with sharing class DefaultApprovalMatrixRuleMapper implements IMatrixRuleMapper {
  private sbaa__ApprovalRule__c rule { get; set; }
  private final String approvalObject { get; set; }

  public static final String DEFAULT_APPROVAL_REQUEST_TEMPLATE_ID = getTemplateIdFor('Approval Request');
  public static final String DEFAULT_APPROVED_TEMPLATE_ID = getTemplateIdFor('Quote Approved');
  public static final String DEFAULT_RECALLED_TEMPLATE_ID = getTemplateIdFor('Quote Recalled');
  public static final String DEFAULT_REJECTED_TEMPLATE_ID = getTemplateIdFor('Quote Rejection');
  public static final String DEFAULT_APPROVAL_TEMPLATE_NAME = 'Approval Request';

  public ApprovalRuleMatrix__c matrixRecord;
  public static final String DEFAULT_APPROVAL_OBJECT = 'SBQQ__Quote__c';
  public static final String DEFAULT_APPROVAL_CONDITION = 'All';
  public static final Boolean ENABLE_SMART_APPROVAL = true;

  public void init(ApprovalRuleMatrix__c matrix) {
    this.matrixRecord = matrix;
    this.rule = new sbaa__ApprovalRule__c();
    if (matrixRecord.Migration_ID__c == null) {
      throw new ApprovalRuleConversionException('ExternalId is required.');
    }

    if (matrixRecord.MD5Hash__c == null) {
      throw new ApprovalRuleConversionException('Matrix MD5Hash__c is required.');
    }
    rule.Migration_ID__c = matrixRecord.Migration_ID__c;
    rule.MatrixMD5Hash__c = matrixRecord.MD5Hash__c;
  }

  private static String getTemplateIdFor(String templateName) {
    try {
      return [SELECT Id FROM sbaa__EmailTemplate__c WHERE Name = :templateName].Id;
    } catch (QueryException e) {
      //Do nothing if Templates aren't there yet
      return null;
    }
  }

  /**
   * Allows Non-Quote Approval Rules to be generated
   *
   * @param matrixRecord
   * @param type
   */
  public DefaultApprovalMatrixRuleMapper(Schema.SObjectType type) {
    this.approvalObject = type.getDescribe().getName();
  }

  /**
   *
   * Default Consutructor - Maps to the Quote Object by default
   */
  public DefaultApprovalMatrixRuleMapper() {
  }

  /**
   * Builds a name for the Approval Rule. Needs to be less than 80 characters
   */
  private void buildName() {
    String name;

    if (matrixRecord.StaticApprover__c != null) {
      name = matrixRecord.StaticApprover__r.Name;
    } else {
      if (matrixRecord.DynamicApproverField__c != null) {
        name = matrixRecord.DynamicApproverField__c.replace('__c', '');
      } else {
        throw new ApprovalRuleConversionException(
          'Missing Approver information. One of Static or Dynamic Approvers needed.'
        );
      }
    }

    // 25May - commented
    // name += ' - ' + matrixRecord.Name;
    name = matrixRecord.Name;

    this.rule.name = name;
  }

  private void mapActiveFlag() {
    this.rule.sbaa__Active__c = this.matrixRecord.Active__c;
  }

  private void mapApprovalChain() {
    this.rule.sbaa__ApprovalChain__c = this.matrixRecord.ApprovalChain__c;
  }

  private void mapApprovalStep() {
    this.rule.sbaa__ApprovalStep__c = this.matrixRecord.ApprovalStep__c;
  }

  /**
   * TODO map to visualforce Templates once they are built
   */
  private void setTemplates() {
    try {
      rule.sbaa__RequestTemplate__c = DEFAULT_APPROVAL_REQUEST_TEMPLATE_ID;
      rule.sbaa__ApprovalTemplate__c = DEFAULT_APPROVED_TEMPLATE_ID;
      rule.sbaa__RecallTemplate__c = DEFAULT_RECALLED_TEMPLATE_ID;
      rule.sbaa__RejectionTemplate__c = DEFAULT_REJECTED_TEMPLATE_ID;
    } catch (Exception e) {
      System.debug('Missing Email Template. Please ensure you have setup all necessary email templates');
      //do nothing if templates don't exist
    }
  }

  private void mapApprover() {
    if (matrixRecord.StaticApprover__c != null) {
      rule.sbaa__Approver__c = matrixRecord.StaticApprover__c;
    } else {
      if (matrixRecord.DynamicApproverField__c != null) {
        rule.sbaa__ApproverField__c = matrixRecord.DynamicApproverField__c;
      } else {
        throw new ApprovalRuleConversionException(
          'Missing Approver information. One of Static or Dynamic Approvers needed.'
        );
      }
    }
  }

  private void setDefaults() {
    rule.sbaa__ConditionsMet__c = DEFAULT_APPROVAL_CONDITION;
    rule.sbaa__TargetObject__c = approvalObject == null ? DEFAULT_APPROVAL_OBJECT : approvalObject;
    rule.sbaa__SmartApprovalIgnoresConditionsMet__c = true;
    rule.sbaa__ApprovalRecipients__c = 'Record Owner;Initial Submitter';
    rule.sbaa__RejectionRecipients__c = 'Record Owner;Initial Submitter';
  }

  /**
     * Sort and Loop conditions
    Use Map<String,List<Condition>>
    Use concat of fieldName + Operator as Map Key
    Build the expression by looping over map.keys
    Each map key becomes an AND group
    Each item in List<Condition> becomes an OR group
     */
  private void buildAdvancedCondition() {
    List<sbaa__ApprovalCondition__c> conditions = buildConditions(matrixRecord);

    // Get conditions grouped by field and operator
    Map<String, List<sbaa__ApprovalCondition__c>> groupedConditions = getGroupedConditions(conditions);

    String advancedCondition = '';

    for (String key : groupedConditions.keySet()) {
      String orGroup = '( ';
      for (sbaa__ApprovalCondition__c orGroupCondition : groupedConditions.get(key)) {
        orGroup += orGroupCondition.sbaa__Index__c;
        orGroup += ' OR ';
      }

      // strip away the last OR
      orGroup = orGroup.left(orGroup.length() - 3);
      orGroup += ')';

      advancedCondition += orGroup + ' AND ';
    }
    // strip away the last OR
    advancedCondition = advancedCondition.left(advancedCondition.length() - 4);

    rule.sbaa__AdvancedCondition__c = advancedCondition;
  }

  private Map<String, List<sbaa__ApprovalCondition__c>> getGroupedConditions(
    List<sbaa__ApprovalCondition__c> conditions
  ) {
    Map<String, List<sbaa__ApprovalCondition__c>> groupedConditions = new Map<String, List<sbaa__ApprovalCondition__c>>();

    for (sbaa__ApprovalCondition__c approvalCondition : conditions) {
      String mapKey = approvalCondition.sbaa__TestedField__c + approvalCondition.sbaa__Operator__c;

      if (!groupedConditions.containsKey(mapKey)) {
        groupedConditions.put(mapKey, new List<sbaa__ApprovalCondition__c>());
      }

      groupedConditions.get(mapKey).add(approvalCondition);
    }

    return groupedConditions;
  }

  public List<sbaa__ApprovalCondition__c> buildConditions(ApprovalRuleMatrix__c mrecord) {
    List<sbaa__ApprovalCondition__c> conditions = new List<sbaa__ApprovalCondition__c>();
    Integer conditionIndex = 100;

    for (
      Schema.FieldSetMember field : Schema.SObjectType.ApprovalRuleMatrix__c.fieldSets.ConditionsMapFields.getFields()
    ) {
      Object objValue = mrecord.get(field.getFieldPath());
      String stringValue = String.valueOf(objValue);

      // Process only If the matrix field has a Value
      // Also ignore if the field has a value but it happens to be a boolean field
      if (
        !String.isEmpty(stringValue) &&
        (Boolean.valueOf(stringValue) || !(field.SObjectField.getDescribe().getType() == Schema.DisplayType.BOOLEAN))
      ) {
        sbaa__ApprovalCondition__c condition = (new ConditionBuilder())
          .buildConditionFor(matrixRecord.Migration_ID__c, field.getFieldPath(), stringValue);
        condition.MatrixMD5Hash__c = mrecord.MD5Hash__c;
        condition.sbaa__Index__c = conditionIndex;
        conditions.add(condition);
        conditionIndex = conditionIndex + 100;
      }
    }

    return conditions;
  }

  /**
   * Builds the Approval Rule by mapping and converting the matrix record
   */
  public sbaa__ApprovalRule__c buildRule(ApprovalRuleMatrix__c matrixRecord) {
    init(matrixRecord);
    setDefaults();
    buildName();
    mapActiveFlag();
    mapApprovalChain();
    mapApprovalStep();
    mapApprover();
    setTemplates();
    buildAdvancedCondition();
    return this.rule;
  }

  public class ApprovalRuleConversionException extends Exception {
  }

  /**
   * Builds a Condition Record based on pre-configured mapping between matrix fields and condition templates
   *
   */
  public class ConditionBuilder {
    public sbaa__ApprovalCondition__c buildConditionFor(
      String matrixExternalId,
      String matrixFieldAPIName,
      String matrixFieldValue
    ) {
      System.debug('>>>>>>>>>>> Querying Custom Metadata for field ' + matrixFieldAPIName);

      // This is fine because SOQL on custom metadata is cached by the platform and does NOT count towards gov limits
      ApprovalMatrixConditionMap__mdt matrixConditionMap = [
        SELECT
          DeveloperName,
          MatrixField__c,
          TestedField__c,
          Operator__c,
          FilterType__c,
          MappedValue__c,
          TestedVariableName__c,
          Smart_Approval__c
        FROM ApprovalMatrixConditionMap__mdt
        WHERE MatrixField__c = :matrixFieldAPIName
      ];

      sbaa__ApprovalCondition__c condition = new sbaa__ApprovalCondition__c();

      condition.sbaa__EnableSmartApproval__c = (matrixConditionMap.Smart_Approval__c == 'Yes' ||
        matrixConditionMap.Smart_Approval__c == 'Default')
        ? true
        : false;

      condition.sbaa__TestedField__c = matrixConditionMap.TestedField__c;
      condition.sbaa__Operator__c = matrixConditionMap.Operator__c;
      condition.sbaa__TestedVariable__c = matrixConditionMap.TestedVariableName__c;

      if (matrixConditionMap.FilterType__c == 'Mapped') {
        condition.sbaa__FilterValue__c = matrixConditionMap.MappedValue__c;
        condition.sbaa__FilterType__c = 'Value';
      } else {
        condition.sbaa__FilterValue__c = matrixFieldValue;
        condition.sbaa__FilterType__c = matrixConditionMap.FilterType__c;
      }

      // condition.Migration_ID__c = DefaultApprovalMatrixRuleMapper.getConditionMD5(
      //   matrixConditionMap.FilterType__c,
      //   condition,
      //   matrixExternalId
      // );
      condition.Migration_ID__c = matrixExternalId + '_' + matrixConditionMap.DeveloperName;

      return condition;
    }
  }

  private static String getConditionMD5(
    String matrixFilterType,
    sbaa__ApprovalCondition__c condition,
    String matrixExternalId
  ) {
    sbaa__ApprovalCondition__c tempCondition;
    if (matrixFilterType == 'Mapped') {
      tempCondition = new sbaa__ApprovalCondition__c(
        sbaa__TestedField__c = condition.sbaa__TestedField__c,
        sbaa__Operator__c = condition.sbaa__Operator__c,
        sbaa__FilterValue__c = condition.sbaa__FilterValue__c
      );
    } else {
      tempCondition = new sbaa__ApprovalCondition__c(
        sbaa__TestedField__c = condition.sbaa__TestedField__c,
        sbaa__Operator__c = condition.sbaa__Operator__c
      );
    }

    return DefaultApprovalMatrixRuleMapper.getMD5Hash(matrixExternalId + JSON.serialize(tempCondition));
  }

  private static String getMD5Hash(String inputString) {
    Blob requestBlob = Blob.valueOf(inputString);
    Blob hash = Crypto.generateDigest('MD5', requestBlob);
    return EncodingUtil.convertToHex(hash);
  }
}