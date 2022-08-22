/*
	@author 	: sudikrt
	@puropse	: Wrapper class user to store the list columns in the fieldset
*/
public with sharing class DataTableColumns {
	@AuraEnabled
    public String label {get;set;}
    @AuraEnabled       
    public String fieldName {get;set;}
    @AuraEnabled
    public String type {get;set;}
    
    public DataTableColumns(String label, String fieldName, String type){
        this.label = label;
        this.fieldName = fieldName;
        this.type = type;            
    }
}