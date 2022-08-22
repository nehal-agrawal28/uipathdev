/*
 *For a given sobject, set the given field
 */
public with sharing class SetSobjectFieldFunction_SL implements SObjectToSObjectFunction {
  private SObjectField field;
  private DescribeFieldResult descrResult;
  private string fieldName;
  private string fieldType;

  public SetSobjectFieldFunction_SL(
    SObjectField field,
    DescribeFieldResult descrResult,
    String fieldName,
    String fieldType
  ) {
    this.field = field;
    this.descrResult = descrResult;
    this.fieldName = fieldName;
    this.fieldType = fieldType;

    if (!descrResult.isAccessible() || !descrResult.isUpdateable() || descrResult.isCalculated()) {
      throw new SetSobjectFieldFunctionnException('The supplied field is not writable');
    }
  }

  public SObject apply(SObject record) {
    try {
      //ideally here we would do an inexpensive defensive check to see if the sobject is creatable
      SObject updatedRecord = record.getSObjectType().newSObject();
      updatedRecord.Id = record.Id;
      string fieldValue = String.valueOf(record.get(field));

      switch on fieldType {
        when 'DATE' {
          updatedRecord.put(fieldName, Date.valueOf(fieldValue));
        }
        when 'BOOLEAN' {
          updatedRecord.put(fieldName, Boolean.valueOf(fieldValue));
        }
        when else {
          updatedRecord.put(fieldName, fieldValue);
        }
      }
      return updatedRecord;
    } catch (Exception e) {
      throw new SetSobjectFieldFunctionnException(e.getMessage());
    }
  }

  public class SetSobjectFieldFunctionnException extends Exception {
  }
}