/*
	@author 	: sudikrt
*/

public with sharing class UIP_PublicSiteCaseUtility {

	/*
		@param String strObjectName 	: required. Object name to get the required filed set
		@param String strFieldSetName 	: required. FieldSet name

		@return  List<DataTableColumns> list of columns in the specified fieldSet
	*/
	public static List<DataTableColumns> getColumns (String strObjectName, String strFieldSetName) {
        Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();            
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(strFieldSetName);
        
        List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
        
        for( Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields() ){
            String dataType = String.valueOf(eachFieldSetMember.getType()).toLowerCase();
            
            DataTableColumns datacolumns = new DataTableColumns( String.valueOf(eachFieldSetMember.getLabel()) , 
                                                                String.valueOf(eachFieldSetMember.getFieldPath()), 
                                                                String.valueOf(eachFieldSetMember.getType()).toLowerCase() );
			lstDataColumns.add(datacolumns);
        }
        return lstDataColumns;
    } 


    /*
		@param String strObjectName 	: required. Object name to get the required filed set
		@param String strFieldSetName 	: required. FieldSet name
		@param String whereCondition 	: optional query condition
		@param Boolean isSingleRow		: param specifies the the response expects single row

		@return  DataTableResponse 		: Wrapper class containing the data
	*/
    public static DataTableResponse getTableData(String strObjectName, String strFieldSetName, String whereCondition, Boolean isSingleRow){                
    	DataTableResponse response = getTableData (strObjectName, strFieldSetName, whereCondition);
    	if (isSingleRow) {
    		if (response.lstDataTableData != null && !response.lstDataTableData.isEmpty ()) {
    			response.firstRow =  response.lstDataTableData [0];
    		}
    	}
    	return response;
    }

    
    /*
		@param String strObjectName 	: required. Object name to get the required filed set
		@param String strFieldSetName 	: required. FieldSet name
		@param String whereCondition 	: optional query condition

		@return  DataTableResponse 		: Wrapper class containing the data
	*/
    public static DataTableResponse getTableData(String strObjectName, String strFieldSetName, String whereCondition){                
        
        Schema.SObjectType SObjectTypeObj = Schema.getGlobalDescribe().get(strObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();            
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(strFieldSetName);
        
        List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
        
        List<String> lstFieldsToQuery = new List<String>();
        
        DataTableResponse response = new DataTableResponse();
        
        for( Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields() ){
            String dataType = String.valueOf(eachFieldSetMember.getType()).toLowerCase();
            
            if(dataType == 'datetime'){
                dataType = 'date';
            }
            DataTableColumns datacolumns = new DataTableColumns( String.valueOf(eachFieldSetMember.getLabel()) , 
                                                                String.valueOf(eachFieldSetMember.getFieldPath()), 
                                                                String.valueOf(eachFieldSetMember.getType()).toLowerCase() );
			lstDataColumns.add(datacolumns);
            lstFieldsToQuery.add(String.valueOf(eachFieldSetMember.getFieldPath()));
        }
        if(! lstDataColumns.isEmpty()){            
            response.lstDataTableColumns = lstDataColumns;
            String query = 'SELECT Id, ' + String.join(lstFieldsToQuery, ',') + ' FROM ' + strObjectName;
            if (!String.isBlank(whereCondition)) {
                query += ' ' + whereCondition;
            }
            System.debug(query);
            response.lstDataTableData = Database.query(query);
        }
        
        return response;
    }
    public static Integer getRandonNumber (Integer len) {
    	String str = string.valueof(Math.abs(Crypto.getRandomLong()));
    	String randomNumber = str.substring(0, len);
    	return Math.abs(Integer.valueOf(randomNumber));
    }

}