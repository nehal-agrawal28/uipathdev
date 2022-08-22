/**
 * File Name: ConditionsAbstract_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public abstract class ConditionsAbstract_PP extends fflib_SObjectDomain implements fflib_ISObjectDomain {
  private static final String SEQUENCE_C = 'Sequence__c';
  private static final String FIELD_C = 'Field__c';

  private static final Pattern DOUBLE_PATTERN = Pattern.compile('^(-?)(0|([1-9][0-9]*))(\\.[0-9]+)?$');
  private static final Pattern INTEGER_PATTERN = Pattern.compile('^-?\\d+');
  private static final Pattern US_DATE_PATTERN = Pattern.compile(
    '^(1[0-2]|0[1-9]|[1-9])/(3[01]|[12][0-9]|0[1-9]|[1-9])/([0-9]{4}|[0-9]{2})$'
  );
  private static final Pattern US_DATETIME_PATTERN = Pattern.compile(
    '^(1[0-2]|0[1-9]|[1-9])/(3[01]|[12][0-9]|0[1-9]|[1-9])/([0-9]{4}|[0-9]{2}) (00|[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9])$'
  );

  public ConditionsAbstract_PP(List<SObject> records) {
    super(records);
  }

  public ConditionsAbstract_PP(List<SObject> records, Schema.SObjectType sObjectType) {
    super(records, sObjectType);
  }

  public fflib_Criteria getCriteriaEvaluator() {
    fflib_Criteria result = new fflib_Criteria();
    for (SObject condition : sort()) {
      String operator = String.valueOf(condition.get('Operator__c'));
      String field = String.valueOf(condition.get(FIELD_C));
      Object value = getConditionValue(condition);
      switch on operator {
        when 'Equals' {
          result.equalTo(field, value);
        }
        when 'Not equal' {
          result.notEqualTo(field, value);
        }
        when 'Contains' {
          result.contains(field, value);
        }
        when 'Less than' {
          result.lessThan(field, value);
        }
        when 'Less than or equal to' {
          result.lessOrEqualTo(field, value);
        }
        when 'Greater than' {
          result.greaterThan(field, value);
        }
        when 'Greater than or equal to' {
          result.greaterOrEqualTo(field, value);
        }
      }
    }
    return result;
  }

  private Object getConditionValue(SObject condition) {
    Object value = condition.get('Value__c');
    if (String.valueOf(value).trim().toUpperCase() == 'TRUE')
      return true;
    if (String.valueOf(value).trim().toUpperCase() == 'FALSE')
      return false;
    if (isInteger(value))
      return Integer.valueOf(value);
    if (isDouble(value))
      return Double.valueOf(value);
    if (isUsDateTime(value))
      return Datetime.parse(String.valueOf(value));
    if (isUsDate(value))
      return Date.parse(String.valueOf(value));

    return condition.get('Value__c');
  }

  public Set<String> getFields() {
    Set<String> result = new Set<String>();
    for (SObject record : getRecords()) {
      result.add(String.valueOf(record.get(FIELD_C)));
    }
    return result;
  }

  public Boolean isUsDate(Object value) {
    return US_DATE_PATTERN.matcher(String.valueOf(value)).matches();
  }

  public Boolean isUsDatetime(Object value) {
    return US_DATETIME_PATTERN.matcher(String.valueOf(value)).matches();
  }

  public Boolean isDouble(Object value) {
    return DOUBLE_PATTERN.matcher(String.valueOf(value)).matches();
  }

  public Boolean isInteger(Object value) {
    return INTEGER_PATTERN.matcher(String.valueOf(value)).matches();
  }

  private List<SObject> sort() {
    List<ConditionWrapper> conditions = getConditionWrappers();
    conditions.sort();
    return getConditions(conditions);
  }

  private List<ConditionWrapper> getConditionWrappers() {
    List<ConditionWrapper> result = new List<ConditionWrapper>();
    for (SObject record : getRecords()) {
      result.add(new ConditionWrapper(record));
    }
    return result;
  }

  private List<SObject> getConditions(List<ConditionWrapper> conditions) {
    List<SObject> result = new List<SObject>();
    for (ConditionWrapper wrapper : conditions) {
      result.add(wrapper.record);
    }
    return result;
  }

  private class ConditionWrapper implements Comparable {
    public SObject record;

    public ConditionWrapper(SObject record) {
      this.record = record;
    }

    public Integer compareTo(Object compareToObj) {
      ConditionWrapper compareTo = (ConditionWrapper) compareToObj;

      Integer thisSequence = Integer.valueOf(this.record.get(SEQUENCE_C));
      Integer compareToSequence = Integer.valueOf(compareTo.record.get(SEQUENCE_C));
      if (thisSequence > compareToSequence) {
        return 1;
      } else if (thisSequence < compareToSequence) {
        return -1;
      }
      return 0;
    }
  }
}