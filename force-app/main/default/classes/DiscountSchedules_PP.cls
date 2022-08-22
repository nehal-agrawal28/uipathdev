/**
 * File Name: DiscountSchedules_PP
 *
 * @author: architect ir. Wilhelmus G.J. Velzeboer
 */
public class DiscountSchedules_PP extends fflib_SObjectDomain implements IDiscountSchedules_PP {
  public DiscountSchedules_PP(List<DiscountSchedule__c> records) {
    super(records, Schema.DiscountSchedule__c.SObjectType);
  }

  public static IDiscountSchedules_PP newInstance(Set<Id> ids) {
    return (IDiscountSchedules_PP) Application_PP.Domain.newInstance(ids);
  }

  public static IDiscountSchedules_PP newInstance(List<DiscountSchedule__c> records) {
    return (IDiscountSchedules_PP) Application_PP.Domain.newInstance(records, Schema.DiscountSchedule__c.SObjectType);
  }

  public List<DiscountSchedule__c> getDiscountSchedules() {
    return (List<DiscountSchedule__c>) getRecords();
  }

  public Set<Id> getDiscountTableIds() {
    Set<Id> result = new Set<Id>();
    for (DiscountSchedule__c record : getDiscountSchedules()) {
      result.add(record.DiscountTable__c);
    }
    return result;
  }

  public List<Id> getDiscountTableIdList() {
    List<Id> result = new List<Id>();
    for (DiscountSchedule__c record : getDiscountSchedules()) {
      result.add(record.DiscountTable__c);
    }
    return result;
  }


  public IDiscountSchedules_PP selectByAccountId(Set<Id> ids) {
    List<DiscountSchedule__c> result = new List<DiscountSchedule__c>();
    for (DiscountSchedule__c record : getDiscountSchedules()) {
      if (ids.contains(record.Account__c)) {
        result.add(record);
      }
    }
    return new DiscountSchedules_PP(result);
  }

  public IDiscountSchedules_PP selectByAccountId(Id id) {
    return selectByAccountId(new Set<Id>{ id, null });
  }

  public IDiscountSchedules_PP sort() {
    List<DiscountSchedules_PP.ScheduleWrapper> schedules = getScheduleWrapper();
    schedules.sort();
    return new DiscountSchedules_PP(getDiscountSchedules(schedules));
  }

  private List<DiscountSchedule__c> getDiscountSchedules(List<DiscountSchedules_PP.ScheduleWrapper> schedules) {
    List<DiscountSchedule__c> result = new List<DiscountSchedule__c>();
    for (ScheduleWrapper wrapper : schedules) {
      result.add(wrapper.record);
    }
    return result;
  }

  private List<ScheduleWrapper> getScheduleWrapper() {
    List<ScheduleWrapper> result = new List<ScheduleWrapper>();
    for (DiscountSchedule__c record : getDiscountSchedules()) {
      result.add(new ScheduleWrapper(record));
    }
    return result;
  }

  private class ScheduleWrapper implements Comparable {
    public DiscountSchedule__c record;

    public ScheduleWrapper(DiscountSchedule__c record) {
      this.record = record;
    }

    public Integer compareTo(Object compareToObj) {
      ScheduleWrapper compareTo = (ScheduleWrapper) compareToObj;

      if (this.record.Sequence__c > compareTo.record.Sequence__c) {
        return 1;
      } else if (this.record.Sequence__c < compareTo.record.Sequence__c) {
        return -1;
      }
      return 0;
    }
  }

  public class Constructor implements fflib_SObjectDomain.IConstructable2 {
    public fflib_SObjectDomain construct(List<SObject> sObjectList) {
      return new DiscountSchedules_PP(sObjectList);
    }

    public fflib_SObjectDomain construct(List<SObject> sObjectList, SObjectType sObjectType) {
      return new DiscountSchedules_PP(sObjectList);
    }
  }
}