public without sharing class BusinessHourMetadata_SV {
  public static Map<String, Id> IdByName {
    get {
      if (IdByName == null) {
        IdByName = new Map<String, Id>();
        for (BusinessHours record : [SELECT Id, Name FROM BusinessHours WHERE IsActive = TRUE]) {
          IdByName.put(record.Name, record.Id);
        }
      }

      return IdByName;
    }
    set;
  }

  public static Map<String, Id> IdByTimeZone {
    get {
      if (IdByTimeZone == null) {
        IdByTimeZone = new Map<String, Id>();
        IdByTimeZone.put('GMT-05:00  Eastern Standard Time', IdByName.get('US(EST) Business Hours(9hrs)'));
        IdByTimeZone.put('GMT-04:00  Eastern Standard Time', IdByName.get('US(EST) Business Hours(9hrs)'));

        IdByTimeZone.put('GMT-06:00  Central Standard Time', IdByName.get('US(CST) Business Hours(9hrs)'));
        IdByTimeZone.put('GMT-05:00  Central Standard Time', IdByName.get('US(CST) Business Hours(9hrs)'));

        IdByTimeZone.put('GMT-08:00  Pacific Standard Time', IdByName.get('US(PST) Business Hours(9hrs)'));
        IdByTimeZone.put('GMT-07:00  Pacific Standard Time', IdByName.get('US(PST) Business Hours(9hrs)'));

        IdByTimeZone.put('GMT-05:00  Atlantic Standard Time', IdByName.get('US(AST) Business Hours(9hrs)'));
        IdByTimeZone.put('GMT-04:00  Atlantic Standard Time', IdByName.get('US(AST) Business Hours(9hrs)'));
      }

      return IdByTimeZone;
    }
    set;
  }
}