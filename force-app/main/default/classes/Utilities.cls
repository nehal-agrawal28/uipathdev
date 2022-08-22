/**
*
* Author:       Daniel Sarchiz
* Date:         16/11/2017
* Description:  Utilities class
*
**/

public class Utilities {
    
    private static List<RecordType> recordTypes;
    
    public static Id getRecordTypeId(String recordTypeName, String objectName) {
        
        Id recordTypeId;
        
        if(recordTypes == null) {
            
            recordTypes = Utilities.getRecordTypes();
        }
        
        for(RecordType rt : recordTypes) {
            
            if(rt.DeveloperName == recordTypeName && rt.SobjectType == objectName) {
                
                recordTypeId = rt.Id;
                
                break;
            }
        }
        
        return recordTypeId;
    }
    
    private static List<RecordType> getRecordTypes() {
        
        return [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE isActive = true];
    }
}