/*******************************************************************************
* @author         :    Bharti Mewada
* @date           :    Aug 2020
* @description    :    Controller class for LWC component (AddresComponent)
* @Revisions      :
        #1        :    Initial Version
*******************************************************************************/

public with sharing class AddressComponentController {
    /** 
    * @Description: Get Bill to adrress on page load
    * @RETURN: current bill to address 
    * @PARAM: String objectRecordId
    * @AUTHOR: Bharti
    */
    @AuraEnabled(cacheable = true)
    public static Address__c getBilltoAddress(String objectRecordId)
    {
       
        Order ord = [SELECT id, Bill_To_Address__c, Ship_To_Address__c from Order WHERE Id =: objectRecordId Limit 1];

        List<Address__c> addressList = [SELECT Id, Name, Account__c, Account__r.Name, Street_Line_1__c, Street_Line_2__c,Primary_Billing__c,Primary_Shipping__c,
												Zip_Postal_Code__c, City__c, State__c, Country__c
										FROM Address__c
										WHERE id =: ord.Bill_To_Address__c limit 1];
       return addressList[0];

    }
    
    /** 
    * @Description    : Get Ship to adrress on page load
    * @RETURN: current ship to address 
    * @PARAM: String objectRcordId
    * @AUTHOR: Bharti
    */
   
    @AuraEnabled(cacheable = true)
    public static Address__c getShipToAddress( String objectRecordId)
    {
        Order ord = [SELECT id, Bill_To_Address__c, Ship_To_Address__c from Order WHERE Id =: objectRecordId Limit 1];

        List<Address__c> addressList = [SELECT Id, Name, Account__c, Account__r.Name, Street_Line_1__c, Street_Line_2__c,Primary_Billing__c,Primary_Shipping__c,
												Zip_Postal_Code__c, City__c, State__c, Country__c
										FROM Address__c
										WHERE Id =: ord.Ship_To_Address__c limit 1];
        return addressList[0];

    }

    /** 
    * @Description: Get all the addresses related to Bill to Account and Customer Account to display in dailog box in LWC.
    * @RETURN: List of addresses
    * @PARAM: String addressType, String objectRecordId
    * @AUTHOR: Bharti
    */
   @AuraEnabled
    public static List<addressWrapper> getWrappedAddress(String addressType, String objectRecordId, String selectedAddressId)
    {   
        Order ord = [SELECT id, Bill_To_Account__c, AccountId from Order WHERE Id =: objectRecordId Limit 1];

        //Adding account Ids in a list to query addresses
        List<String> accountIds = new List<Id>();
        if(addressType == 'billToAddress')
        {
            accountIds.add(ord.Bill_To_Account__c);
        }else{
            accountIds.add(ord.Bill_To_Account__c);
            accountIds.add(ord.AccountId);
        }
        system.debug('selected address : '+selectedAddressId);  

        //Query all address for above accounts
        List<Address__c> addressList = [SELECT Id, Name, Account__c, Account__r.Name, Street_Line_1__c, Street_Line_2__c,Primary_Billing__c,Primary_Shipping__c,
												Zip_Postal_Code__c, City__c, State__c, Country__c
										FROM Address__c
										WHERE Account__c =: accountIds
                                        AND Stripe_Customer_ID__c = null]; 

        //Create address wrapper list around these addresses
        List<addressWrapper>  addressWrapperList = new  List<addressWrapper>();  
        String ischecked = '';
        for(Address__c add : addressList)
        {
            ischecked = '';
            if(add.Id == selectedAddressId)
                ischecked = 'checked';
            addressWrapperList.add(new addressWrapper(add.Id, ischecked, add));  

        }  
       return addressWrapperList;

    }

    /** 
    * @description: Update selected Bill to address and Ship to address on Order
    * @RETURN: 
    * @PARAM: String addressType, String selectedAddressId, String objectRecordId
    * @AUTHOR: Bharti
    */
    @AuraEnabled
    public static void updateAddress(String addressType, String selectedAddressId, String objectRecordId)
    {
        if (selectedAddressId != null) {
            Order odr = new Order(id = objectRecordId);
           
            if(addressType == 'billToAddress') 
            {
                odr.Bill_To_Address__c = selectedAddressId;
            }else{
                odr.Ship_To_Address__c = selectedAddressId;
            }
        
            try{
                update odr;
            } 
           catch(Exception ex){
                throw new AuraHandledException(label.Order_Int_Address_Update_Error_Msg +' '+ ex.getMessage());
            }
        }
       
    }

    // Wrapper class to address to show pre-selected address on the change address popup
    public class addressWrapper
    {
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public String isChecked;
        @AuraEnabled
        public Address__c address;
        public addressWrapper(String Id, String isChecked, Address__c address){
            this.address = address;
            this.isChecked = isChecked;
            this.Id = Id;
        }
        
    }
       
}