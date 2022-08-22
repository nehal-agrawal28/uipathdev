public with sharing class PicklistMsg_CM {
  @AuraEnabled
  public String label { get; set; }
  @AuraEnabled
  public String value { get; set; }

  public PicklistMsg_CM(String value, String label) {
    this.label = label;
    this.value = value;
  }
}