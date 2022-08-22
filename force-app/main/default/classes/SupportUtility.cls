/*
Author : Deepali from WarpDrive
Purpose : To have all utility methods used in support cases.  
*/
public  without sharing class SupportUtility{

	public static Map<String,Id> recordTypeIdMap = new Map<String,Id>();

	//Added by WarpDrive: Deepali
    //Purpose : To query record type and return the record type id. 
    public static Id getRecordTypeIdByName(String objAPIName, String recordTypeName){
      //check if the static map contains the recordtype id 
      if(recordTypeIdMap.containsKey(objAPIName+'-'+recordTypeName)){
        //if it contains then get the id from map 
        return recordTypeIdMap.get(objAPIName+'-'+recordTypeName);
      } else {
        // else get the id from sschema         
        //Id recordTypeId = Schema.getGlobalDescribe().get(objAPIName).getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        Id recordTypeId = Schema.getGlobalDescribe().get(objAPIName).getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
        //put the id in the map for future reference and return the id
        recordTypeIdMap.put(objAPIName+'-'+recordTypeName, recordTypeId);
        return recordTypeId;
      }
    }
}