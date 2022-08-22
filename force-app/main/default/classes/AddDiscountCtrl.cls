public class AddDiscountCtrl 
{
    @auraEnabled
    public static list<ProductOption> getInfo(string oppId)
    {
        list<ProductOption> productList = new List<ProductOption>();
        
        list<OpportunityLineItem> oliList = [select id, name, discount, ListPrice, Quantity, TotalPrice from OpportunityLineItem where OpportunityId = :oppId];       
                
        for(OpportunityLineItem oli : oliList)
        {    
            if(oli.Discount != null)
                productList.add(new ProductOption(oli.Id, oli.ListPrice.toPlainString(), oli.Name, oli.Quantity.toPlainString(), oli.TotalPrice.toPlainString(), oli.Discount.toPlainString()));
            else
                productList.add(new ProductOption(oli.Id, oli.ListPrice.toPlainString(), oli.Name, oli.Quantity.toPlainString(), oli.TotalPrice.toPlainString(), ''));
        }
        
        return productList;
    }
    
    @auraEnabled
    public static list<string> getOptions()
    {
        list<string> discountOptions = new list<string>();
        
        discountOptions.add('-- Please Select --');
        discountOptions.add('Apply to all products');
        discountOptions.add('Apply to each product indvidually');
        
        return discountOptions;
    }
    
    @auraEnabled
    public static discountResponse calculateDiscount(string apply, string oppProd, string oppId, string disc)
    {
       
        decimal discount;
        
        if(apply != null && apply != '')
        {
            if(apply == 'Apply to all products' && disc != null && disc != '')
                discount  = decimal.valueOf(disc);
            else if(apply == 'Apply to each product indvidually')
                discount = 0;
            else
                return new discountResponse('true','Please select a value for the discount.');
        }
        else        
            return new discountResponse('true','Please choose whether you wish to apply a discount to all products or just individual products.');
                
        list<OpportunityLineItem> oliList = [select id, name, discount from OpportunityLineItem where OpportunityId = :oppId];
              
        if(apply == 'Apply to all products')
        {               
            for(OpportunityLineItem oli : oliList)
            {    
                oli.Discount = discount;
            }
            
            update oliList;
            
            return new discountResponse('false','Discount applied successfully to all products.');
        }
        else
        {
            list<ProductOption> oppProdList = (list<ProductOption>)System.JSON.deserializeStrict(oppProd, List<ProductOption>.Class);
            
            map<string,string> oppProdMap = new map<string,string>();
            
            for(ProductOption po : oppProdList)
            {
                oppProdMap.put(po.theId, po.discount);                        
            }
            
            string discountedProducts = '';
            
            for(OpportunityLineItem oli : oliList)
            {
                if(oppProdMap.get(oli.id) != null && oppProdMap.get(oli.id) != '')
                {
                    if(oli.Discount != decimal.valueOf(oppProdMap.get(oli.id)))
                    {                    
                        discountedProducts += oli.Name + ', ';
                        oli.Discount = decimal.valueOf(oppProdMap.get(oli.id));
                    }
                }
                else                
                    return new discountResponse('true','Please make sure each of the discount fields has a value.');                
            }
            
            if(discountedProducts != '')
            {
                update oliList; 
                
                discountedProducts = discountedProducts.removeEnd(', ');
                discountedProducts += '.';
                
            }
            return new discountResponse('false', 'Discount applied successfully to all products.');
           
        }
            
    }            
  
    public class ProductOption
    {
        @auraEnabled
        public string theId { get; set; }
        @auraEnabled
        public string value { get; set; }
        @auraEnabled
        public string label { get; set; }
        @auraEnabled
        public string quantity { get; set; }
        @auraEnabled
        public string total { get; set; }
        @auraEnabled
        public string discount { get; set; }        
        
        public ProductOption(string i, string v, string l, string q, string t, string d)
        {	
            label = l;
            
            theid = i; 
            
            if( v != null && v != '')
                value = v;
            else
                value = '0';
            
            if( q != null && q != '')
                quantity = q;
            else
                quantity = '0';
            
            if( t != null && t != '')
                total = t;
            else
                total = '0';
            
            if( d != null && d != '')
                discount = d;
            else
                discount = '0';           
        } 
    }
    
    public class discountResponse
    {	
        @auraEnabled
        string errorFound { get; set; }
        
        @auraEnabled
        string message { get; set; }
        
        public discountResponse(string ef, string m)
        {
            errorFound = ef;
            message = m;
        }
        
    }    
}