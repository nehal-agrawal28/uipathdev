public with sharing class CPQPicklistMsg_SL {
  @AuraEnabled
  public String label { get; set; }
  @AuraEnabled
  public String value { get; set; }

  public CPQPicklistMsg_SL(String value, String label) {
    this.label = label;
    this.value = value;
  }
}