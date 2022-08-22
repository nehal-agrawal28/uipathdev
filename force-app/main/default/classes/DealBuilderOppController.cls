public with sharing class DealBuilderOppController {
  public class DealBuilderWrapper {
    @AuraEnabled
    public List<FieldSetWrapper> oppFields { get; set; }
    @AuraEnabled
    public Boolean askConfirmation { get; set; }
    @AuraEnabled
    public String cpqDefaultRT { get; set; }
    @AuraEnabled
    public Account currentAccount { get; set; }
  }

  public class FieldSetWrapper {
    @AuraEnabled
    public String fieldAPI { get; set; }
    @AuraEnabled
    public Boolean required { get; set; }
    @AuraEnabled
    public Boolean disabled { get; set; }
    @AuraEnabled
    public Object defaultValue { get; set; }

    public FieldSetWrapper(String fieldAPI, Boolean required, Boolean disabled, Object defaultValue) {
      this.fieldAPI = fieldAPI;
      this.required = required;
      this.disabled = disabled;
      this.defaultValue = defaultValue;
    }
  }

  @AuraEnabled(cacheable=true)
  public static DealBuilderWrapper getInitialData(String accountId) {
    DealBuilderWrapper wrapper = new DealBuilderWrapper();

    wrapper.askConfirmation = [
        SELECT Id, ContractNumber, StartDate, EndDate
        FROM Contract
        WHERE AccountId = :accountId AND EndDate >= TODAY
        ORDER BY StartDate ASC
      ]
      .size() > 0
      ? true
      : false;

    wrapper.oppFields = newOpportunityFields(accountId);

    wrapper.cpqDefaultRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
      .get('CPQ_Default')
      .getRecordTypeId();

    wrapper.currentAccount = [SELECT Id, Credit_Hold__c FROM Account WHERE Id = :accountId];

    return wrapper;
  }

  private static List<FieldSetWrapper> newOpportunityFields(String accountId) {
    List<FieldSetWrapper> fList = new List<FieldSetWrapper>();
    for (
      Schema.FieldSetMember f : Schema.getGlobalDescribe()
        .get('Opportunity')
        .getDescribe()
        .fieldSets.getMap()
        .get('New_Opportunity')
        .getFields()
    ) {
      if (f.getFieldPath() == 'AccountId') {
        fList.add(new FieldSetWrapper(f.getFieldPath(), f.getRequired(), true, accountId));
      } else if (f.getFieldPath() == 'CloseDate') {
        Date closeDate = System.Today().addMonths(1).toStartofMonth().addDays(-1);
        fList.add(new FieldSetWrapper(f.getFieldPath(), f.getRequired(), false, closeDate));
      } else if (f.getFieldPath() == 'StageName') {
        fList.add(new FieldSetWrapper(f.getFieldPath(), f.getRequired(), false, 'Discovery'));
      } else {
        fList.add(new FieldSetWrapper(f.getFieldPath(), f.getRequired(), false, null));
      }
    }
    return fList;
  }
}