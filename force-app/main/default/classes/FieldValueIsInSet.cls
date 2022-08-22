public with sharing class FieldValueIsInSet implements SObjectPredicate {
  Schema.SObjectField fieldToken;
  Set<Object> objSet;
  public FieldValueIsInSet(Schema.SObjectField fieldToken, List<SObject> records, Set<Object> objSet) {
    this.fieldToken = fieldToken;
    this.objSet = objSet;
  }
  public Boolean apply(SObject record) {
    return objSet.contains((Object) record.get(fieldToken));
  }
}