public with sharing class PafListViewDownloadController_PP {
  public transient String contents { public get; private set; }

  private static final String QUOTE = '"';
  private static final String COLUMN_SEPARATOR = ',';
  private static final String FIELD_SEPARATOR = ',';
  private static final String LINE_BREAK = '\n';

  public PafListViewDownloadController_PP() {
    Map<String, String> params = ApexPages.currentPage().getParameters();
    contents = '"hello","World"';
  }

  private List<Schema.SObjectField> columns = new List<Schema.SObjectField>{
    Partner_Application_Form__c.Name,
    Partner_Application_Form__c.Full_Name__c,
    Partner_Application_Form__c.Application_Status__c,
    Partner_Application_Form__c.Application_Substatus__c,
    Partner_Application_Form__c.UiPath_Status__c,
    Partner_Application_Form__c.Country__c,
    Partner_Application_Form__c.CreatedDate
  };

  public PafListViewDownloadController_PP(ApexPages.StandardSetController stdController) {
    List<Partner_Application_Form__c> forms = Database.query(
      String.format(
        'SELECT {0} FROM Partner_Application_Form__c ORDER BY Name',
        new List<String>{ getQueryFieldString(columns) }
      )
    );

    contents = getHeader(columns) + LINE_BREAK + getRows(columns, forms) + LINE_BREAK + '"Have a nice day!"';
  }

  private String getQueryFieldString(List<SObjectField> sObjectFields) {
    String result = '';
    for (SObjectField field : sObjectFields) {
      result += field.getDescribe().getName() + FIELD_SEPARATOR;
    }
    return result.left(result.length() - 1);
  }

  private String getHeader(List<SObjectField> sObjectFields) {
    String result = '';
    for (SObjectField field : sObjectFields) {
      result += QUOTE + field.getDescribe().getLabel() + QUOTE + COLUMN_SEPARATOR;
    }
    return result.left(result.length() - 1);
  }

  private String getRows(List<SObjectField> sObjectFields, List<Partner_Application_Form__c> forms) {
    String result = '';
    for (Partner_Application_Form__c form : forms) {
      for (SObjectField field : sObjectFields) {
        result += QUOTE + ((form.get(field) != null) ? form.get(field) : '') + QUOTE + COLUMN_SEPARATOR;
      }
      result += LINE_BREAK;
    }
    return result;
  }
}