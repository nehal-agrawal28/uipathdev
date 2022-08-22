public without sharing class Utilities_PP {
  public static String getDomainFromEmail(String emailAddress) {
    return emailAddress.substringAfter('@').toLowerCase();
  }

  public static String getRandomNumbersAsString(Integer numberOfDigits) {
    String randomNumber = '';
    for (Integer i = 0; i < numberOfDigits; i++) {
      randomNumber += String.valueOf(Integer.valueof((Math.random() * 10)));
    }

    return randomNumber;
  }

  public static List<Integer> cloneAndSort(List<Integer> unsortedIntegers) {
    return (List<Integer>) cloneAndSort((List<Object>) unsortedIntegers);
  }

  public static List<Object> cloneAndSort(List<Object> unsorted) {
    List<Object> result = unsorted.clone();
    result.sort();
    return result;
  }

  public static Object firstValue(List<Object> objects) {
    if (isEmpty(objects)) {
      return null;
    }

    return objects.get(0);
  }

  public static String getSandboxName() {
    return UserInfo.getUserName().substringAfterLast('.');
  }

  public static Boolean getIsSandbox() {
    return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
  }

  public static String getSalesforceBaseUrl() {
    //URL.getSalesforceBaseUrl().toExternalForm() does not work from the portal partner experience
    String baseURL = 'https://uipath.lightning.force.com';
    if (Utilities_PP.getIsSandbox()) {
      baseURL = 'https://uipath--' + Utilities_PP.getSandboxName() + '.lightning.force.com/';
    }
    return baseURL;
  }

  public static Object lastValue(List<Object> objects) {
    if (isEmpty(objects)) {
      return null;
    }

    return objects.get(objects.size() - 1);
  }

  public static List<String> objectToString(List<Object> objects) {
    List<String> result = new List<String>();
    if (isEmpty(objects)) {
      return result;
    }

    for (Object obj : objects) {
      result.add(String.valueOf(obj));
    }
    return result;
  }

  public static List<String> objectToString(Set<Object> objects) {
    return objectToString(new List<Object>(objects));
  }

  public static Set<Id> objectToIds(Set<Object> objects) {
    Set<Id> results = new Set<Id>();
    for (Object obj : objects) {
      results.add((Id) obj);
    }
    return results;
  }

  public static List<Object> reverse(List<Object> objects) {
    if (isNotEmpty(objects)) {
      Integer i = 0;
      Integer j = objects.size() - 1;
      Object tmp;
      while (j > i) {
        tmp = objects[j];
        objects[j] = objects[i];
        objects[i] = tmp;
        j--;
        i++;
      }
    }
    return objects;
  }

  public static List<SObject> reverse(List<SObject> sObjects) {
    if (isNotEmpty(sObjects)) {
      Integer i = 0;
      Integer j = sObjects.size() - 1;
      SObject tmp;
      while (j > i) {
        tmp = sObjects[j];
        sObjects[j] = sObjects[i];
        sObjects[i] = tmp;
        j--;
        i++;
      }
    }
    return sObjects;
  }

  public static List<String> lowerCase(List<String> strings) {
    List<String> result = new List<String>();
    if (isNotEmpty(strings)) {
      for (String s : strings) {
        result.add(s == null ? null : s.toLowerCase());
      }
    }
    return result;
  }

  public static List<String> upperCase(List<String> strings) {
    List<String> result = new List<String>();
    if (isNotEmpty(strings)) {
      for (String s : strings) {
        result.add(s == null ? null : s.toUpperCase());
      }
    }
    return result;
  }

  public static Boolean isEmpty(List<Object> objects) {
    return (null == objects || objects.isEmpty());
  }

  public static Boolean isEmpty(List<SObject> sObjects) {
    return (null == sObjects || sObjects.isEmpty());
  }

  public static Boolean isNotEmpty(Object[] objectArray) {
    return !isEmpty(objectArray);
  }

  public static Boolean isNotEmpty(SObject[] objectArray) {
    return !isEmpty(objectArray);
  }

  public static Datetime maxDatetime(List<Datetime> input) {
    return (Datetime) max((List<Object>) input);
  }

  public static Object max(List<Object> input) {
    if (isEmpty(input)) {
      return null;
    }

    List<Object> result = cloneAndSort(input);
    return lastValue(result);
  }

  public static Datetime minDatetime(List<Datetime> input) {
    return (Datetime) min((List<Object>) input);
  }

  public static Object min(List<Object> input) {
    if (isEmpty(input)) {
      return null;
    }

    List<Object> result = cloneAndSort(input);
    return firstValue(result);
  }

  public static List<Object> pluck(List<SObject> sObjects, SObjectField sObjectField) {
    List<Object> result = new List<Object>();
    if (isNotEmpty(sObjects)) {
      for (SObject sObj : sObjects) {
        result.add(sObj.get(sObjectField));
      }
    }
    return result;
  }

  public static Set<Object> pluckSet(List<SObject> sObjects, SObjectField sObjectField) {
    return new Set<Object>(pluck(sObjects, sObjectField));
  }

  public static Set<Id> pluckIdField(List<SObject> sObjects, SObjectField sObjectField) {
    Set<Id> result = new Set<Id>();
    if (isEmpty(sObjects)) {
      return result;
    }

    for (SObject sObj : sObjects) {
      result.add((Id) sObj.get(sObjectField));
    }
    return result;
  }

  public static Set<String> pluckStringField(List<SObject> sObjects, SObjectField sObjectField) {
    Set<String> result = new Set<String>();
    if (isEmpty(sObjects)) {
      return result;
    }

    for (SObject sObj : sObjects) {
      result.add((String) sObj.get(sObjectField));
    }
    return result;
  }

  public static Map<Integer, Set<Id>> splitIdSet(Set<Id> idSet, Integer batchSize) {
    if (idSet.isEmpty()) {
      return new Map<Integer, Set<Id>>();
    } else if (idSet.size() <= batchSize) {
      return new Map<Integer, Set<Id>>{ 0 => idSet };
    }

    Integer batch = 0;
    Map<Integer, Set<Id>> result = new Map<Integer, Set<Id>>{ 0 => new Set<Id>() };
    List<Id> idList = new List<Id>(idSet);
    for (Integer i = 0; i < idList.size(); i++) {
      result.get(batch).add(idList.get(i));

      if ((i + 1) >= (batchSize * (batch + 1))) {
        batch++;
        result.put(batch, new Set<Id>());
      }
    }

    return result;
  }
}