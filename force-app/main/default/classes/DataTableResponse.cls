public with sharing class DataTableResponse {
    @AuraEnabled
    public List<DataTableColumns> lstDataTableColumns {get;set;}
    @AuraEnabled
    public List<sObject> lstDataTableData {get;set;} 
    @AuraEnabled
    public sObject firstRow {get;set;} 
    
    public DataTableResponse(){
        lstDataTableColumns = new List<DataTableColumns>();
        lstDataTableData = new List<sObject>();
    }
}