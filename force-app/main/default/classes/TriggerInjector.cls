/**
* @author: Swati Gour
* @date: 08/01/2021
* @description: This class is used to call trigger handler for the passed object in a sequence.
*               This helps to seperate out trigger handler and trigger in different package.
*               TriggerHandler implementation class should extends TriggerHandler class.
*/
public inherited sharing class TriggerInjector {
    
    private final static String ACTIVE = 'Active';
    
    /**
     * It is used to call trigger handler as per the configuration defined
     * @param: 
     *  sobjType: Sobject Type like Account.SobjectType i.e. OBJECTAPINAME.SobjectType
     */
    public static void handle(SObjectType triggerType) {
        // Discover bindings made against the given sobject type
        //   (bindings are always returned in sequence if specified)
        List<di_Binding> bindings = di_Injector.Org.Bindings.bySObject(triggerType).get();
     
        for(di_Binding binding : bindings) {
            di_BindingConfigWrapper bindingWrap = (di_BindingConfigWrapper)binding.Data; // e.g. access to Binding__mdt if additional fields have been added
            if(bindingWrap.Status == ACTIVE){
                fflib_SObjectDomain.triggerHandler(Type.forName((String)binding.To));
            }
        }
     }
}