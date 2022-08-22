/**
 * Created by paul.bircham on 2019-05-16.
 */

public with sharing class CPQQuoteContractedPricesService {

    private static String[] PRODUCT_FAMILY = new String[]{'Core Product', 'Non-Production'};
    private static String GEN_CON_PRICE_METHOD = 'Price';

    public static void setGenerateContractPrices(List<SBQQ__Quote__c> quotes) {


        Set<Id> scopeProduct2s = new Set<Id>();
        scopeProduct2s= getScopeProducts();


        if(scopeProduct2s.size() == 0){
            return;
        }

        Map<Id,List<SBQQ__QuoteLine__c>> quoteLineMap = new Map<Id,List<SBQQ__QuoteLine__c>>();
        quoteLineMap = getQuoteLines(quotes);


        Map<Id,List<SBQQ__ContractedPrice__c>> contractedPriceMap = new Map<Id,List<SBQQ__ContractedPrice__c>>();
        contractedPriceMap = getContractedPrices(quotes);

        List<SBQQ__QuoteLine__c> qlisToUpdate = new List<SBQQ__QuoteLine__c>();

        for(SBQQ__Quote__c q : quotes){

            List<SBQQ__QuoteLine__c> qlis = new List<SBQQ__QuoteLine__c>();
             qlis = quoteLineMap.get(q.Id);

            List<SBQQ__QuoteLine__c> inScopeQlis = new List<SBQQ__QuoteLine__c>();
            Set<Id> inScopeQliProdIds = new Set<id>();


            //get a list of QLIs that have in-scope products
            for(SBQQ__QuoteLine__c qli : qlis){

                if(scopeProduct2s.contains(qli.SBQQ__Product__c)){
                    inScopeQlis.add(qli);
                    inScopeQliProdIds.add(qli.SBQQ__Product__c);
                }

            }

            //check the in-scope qlis for existing contracted prices
            List<SBQQ__ContractedPrice__c> accContractedPrices = new List<SBQQ__ContractedPrice__c>();
            accContractedPrices = contractedPriceMap.get(q.SBQQ__Account__c);

            Set<Id> existingContractedPrIds = new Set<Id>();

            Map<Id, List<SBQQ__ContractedPrice__c>> accContractedPricesByprodIds = new Map<Id, List<SBQQ__ContractedPrice__c>>();
            accContractedPricesByprodIds = getAccContractedPricesByProdIds(accContractedPrices);


            for(SBQQ__ContractedPrice__c cp : accContractedPrices){
                existingContractedPrIds.add(cp.SBQQ__Product__c);
            }


            //update qlis that need a contracted price generated
            for(SBQQ__QuoteLine__c quoteLine : inScopeQlis){

                if(inScopeQliProdIds.contains(quoteLine.SBQQ__Product__c)){

                    List<SBQQ__ContractedPrice__c> cps = new List<SBQQ__ContractedPrice__c>();
                    cps = accContractedPricesByprodIds.get(quoteLine.SBQQ__Product__c);

                    if(!hasActiveContractPrice(cps,quoteLine)){
                        quoteLine.SBQQ__GenerateContractedPrice__c = GEN_CON_PRICE_METHOD;
                        qlisToUpdate.add(quoteLine);
                    }


                }

            }

        }
        System.Savepoint sp = Database.setSavepoint();
        try{
            update qlisToUpdate;
        }
        catch (Exception e){
            System.debug(LoggingLevel.ERROR, 'CPQQuoteContractedPricesService has encountered an error: ' + e.getMessage());
            Database.rollback(sp);
        }


    }


    /**
     * Utility to fetch the in-scope Product records
     *
     * @return a list of in-scope products
     */
    @TestVisible
    private static Set<Id> getScopeProducts(){

        List<Product2> prods = [SELECT Id, Name, Family, SBQQ__SubscriptionPricing__c
        FROM Product2
        WHERE Family IN :PRODUCT_FAMILY
        AND SBQQ__SubscriptionPricing__c !=''
        AND SBQQ__ConfigurationEvent__c = ''
        AND SBQQ__ConfigurationType__c = ''];

        Set<Id> prodIds = new Set<Id>();

        for(Product2 p : prods){
            prodIds.add(p.Id);
        }

        return prodIds;
    }


    /**
     * Utility to fetch quote lines related to trigger quotes
     *
     * @param quotes quotes to process
     *
     * @return map of quote id and a list of related quotelines
     */
    @TestVisible
    private static Map<Id,List<SBQQ__QuoteLine__c>> getQuoteLines(List<SBQQ__Quote__c> quotes){


        Map<Id,List<SBQQ__QuoteLine__c>> quoteLineMap = new Map<Id,List<SBQQ__QuoteLine__c>>();

        List<SBQQ__QuoteLine__c> scopeQlis = [SELECT Id, SBQQ__Quote__c, SBQQ__ContractedPrice__c, SBQQ__Product__c, SBQQ__EffectiveEndDate__c, SBQQ__EffectiveStartDate__c, SBQQ__Product__r.Name FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quotes];

        for(SBQQ__Quote__c quote : quotes){

            List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

            for(SBQQ__QuoteLine__c quoteLine : scopeQlis){

                if(quoteLine.SBQQ__Quote__c == quote.Id) quoteLines.add(quoteLine);

            }

            quoteLineMap.put(quote.Id,quoteLines);

        }


        return quoteLineMap;

    }

    /**
     * Utility to fetch contracted prices related to trigger quote.Account
     *
     * @param quotes quotes to process
     *
     * @return map of account id and a list of related contracted prices
     */
    @TestVisible
    private static Map<Id,List<SBQQ__ContractedPrice__c>> getContractedPrices(List<SBQQ__Quote__c> quotes){

        Map<Id,List<SBQQ__ContractedPrice__c>> contractedPriceMap = new Map<Id,List<SBQQ__ContractedPrice__c>>();

        Set<Id> accIds = new Set<Id>();

        for(SBQQ__Quote__c quote : quotes){
            accIds.add(quote.SBQQ__Account__c);
        }

        List<SBQQ__ContractedPrice__c> scopeContractedPrices = [SELECT Id, SBQQ__Product__c, SBQQ__Product__r.Name, SBQQ__EffectiveDate__c, SBQQ__ExpirationDate__c, SBQQ__Account__c FROM SBQQ__ContractedPrice__c WHERE SBQQ__Account__c IN: accIds];

        for(Id accId : accIds){

            List<SBQQ__ContractedPrice__c> contractedPrices = new List<SBQQ__ContractedPrice__c>();

            for(SBQQ__ContractedPrice__c contractedPrice : scopeContractedPrices){

                if(contractedPrice.SBQQ__Account__c == accId) contractedPrices.add(contractedPrice);

            }

            contractedPriceMap.put(accId,contractedPrices);

        }

        return contractedPriceMap;

    }

    /**
     * Utility to fetch contracted prices related to trigger quote.Account organised by prod id
     *
     * @param quotes an account's contracted prices
     *
     * @return map of prod id and a list of contracted prices for that prod Id
     */
    @TestVisible
    private static Map<Id, List<SBQQ__ContractedPrice__c>> getAccContractedPricesByProdIds(List<SBQQ__ContractedPrice__c> contractedPrices){

        Map<Id,List<SBQQ__ContractedPrice__c>> contractedPriceMap = new Map<Id,List<SBQQ__ContractedPrice__c>>();

        Set<Id> prodIds = new Set<Id>();

        for(SBQQ__ContractedPrice__c cp : contractedPrices){
            prodIds.add(cp.SBQQ__Product__c);
        }

        for(Id prodId : prodIds){

            List<SBQQ__ContractedPrice__c> cps = new List<SBQQ__ContractedPrice__c>();

            for(SBQQ__ContractedPrice__c cp : contractedPrices){

                if(cp.SBQQ__Product__c == prodId) cps.add(cp);

            }

            contractedPriceMap.put(prodId, cps);

        }

        return contractedPriceMap;



    }

    /**
     * Returns a boolean as to whether a specific product has an active contracted price under an account
     *
     * @param contractedPrices contracted prices for a specific account and product combination
     * @param qli a quote line to check
     *
     * @return
     */
    @TestVisible
    private static Boolean hasActiveContractPrice (List<SBQQ__ContractedPrice__c> contractedPrices, SBQQ__QuoteLine__c qli){

        if(contractedPrices != null && qli != null){

            if(contractedPrices.size() > 0){

                for(SBQQ__ContractedPrice__c cp :  contractedPrices){

                    //if cp has both dates and the qli dates fall between
                    if(qli.SBQQ__EffectiveStartDate__c >= cp.SBQQ__EffectiveDate__c
                            && qli.SBQQ__EffectiveEndDate__c <= cp.SBQQ__ExpirationDate__c ){
                        return true;
                    }
                    //if the cp has only effective date
                    if(qli.SBQQ__EffectiveStartDate__c >= cp.SBQQ__EffectiveDate__c
                            && cp.SBQQ__ExpirationDate__c == null){
                        return true;
                    }

                }
            }

        }

        return false;

    }



}