/*
 *For a given record, negate the boolean for a given field
 */
public with sharing class NegateBooleanFunction_SL implements SObjectToSObjectFunction {
  private string fieldName;

  public NegateBooleanFunction_SL(String fieldName) {
    this.fieldName = fieldName;
  }

  public SObject apply(SObject record) {
    //TODO - for the given object and field, check the field exists
    //TODO - check the given field on the record exists and returns a boolean
    record.put(fieldName, !(Boolean) record.get(fieldName));
    return record;
  }
}