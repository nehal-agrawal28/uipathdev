public class AddDiscountVfCtrl 
{
    public Id oppId { get; set; }    
    public list<ProductOption> productList { get; set; }    
    public list<SelectOption> discountOption  { get; set; }
    list<ProductOption> oppProdList { get; set; }    
    public string apply { get; set; }
    public boolean applyAll { get; set; }
    public boolean applyEach { get; set; }
    public string oppProd { get; set; }
    public string disc { get; set; }
    
    public AddDiscountVfCtrl(ApexPages.StandardController sc)
    {                
        oppId = sc.getId();        
        
        applyAll = false; 
        applyEach = false;
        
        generateProductList(oppId);        
        
        discountOption = new list<SelectOption>();
        
        discountOption.add(new SelectOption('','-- Please Select --'));
        discountOption.add(new SelectOption('Apply to all products','Apply to all products'));
        discountOption.add(new SelectOption('Apply to each product indvidually','Apply to each product indvidually'));
        
    }
    
    public void generateFields()
    {
        if(apply == 'Apply to all products')
        {
            applyAll = true;
            applyEach = false;
            
            if(disc != null || disc != '')
            	disc = '0';
        }
        else if(apply == 'Apply to each product indvidually')
        {
            applyEach = true;
            applyAll = false;
            
            if(disc != null || disc != '')
            	disc = '0';            
        }
        else
        {          
            applyEach = false; 
            applyAll = false;
            
            if(disc != null || disc != '')
            	disc = '0';
        }
    }
    
    public void generateProductList(id oppId)
    {
        productList = new list<ProductOption>();
        
        list<OpportunityLineItem> oliList = [select id, name, discount, ListPrice, Quantity, TotalPrice from OpportunityLineItem where OpportunityId = :oppId];
    	
        for(OpportunityLineItem oli : oliList)
        {    
            if(oli.Discount != null)               
                productList.add(new ProductOption(oli.ListPrice.toPlainString(), oli.Name, oli.Id, oli.Quantity.toPlainString(), oli.TotalPrice.toPlainString(), oli.Discount.toPlainString()));
            else
                productList.add(new ProductOption(oli.ListPrice.toPlainString(), oli.Name, oli.Id, oli.Quantity.toPlainString(), oli.TotalPrice.toPlainString(), ''));
        }
    }
    
    public void calculateDiscount()
    {
       
        decimal discount;
        
        if(apply != null && apply != '')
        {
            if(apply == 'Apply to all products' && disc != null && disc != '')
                discount  = decimal.valueOf(disc);
            else if(apply == 'Apply to each product indvidually')
                discount = 0;
            else
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select a value for the discount.'));
        }
        else        
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please choose whether you wish to apply a discount to all products or just individual products.'));
                
        list<OpportunityLineItem> oliList = [select id, name, discount from OpportunityLineItem where OpportunityId = :oppId];
               
        if(apply == 'Apply to all products')
        {               
            for(OpportunityLineItem oli : oliList)
            {    
                oli.Discount = discount;
            }
            
            update oliList;
            
            generateProductList(oppId);            
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Discount applied successfully to all products.'));            
        }
        else
        {                      
            map<string,string> oppProdMap = new map<string,string>();
            
            for(ProductOption po : productList)
            {
                oppProdMap.put(po.idValue, po.discount);                        
            }
            
            string discountedProducts = '';
            
            for(OpportunityLineItem oli : oliList)
            {
                if(oppProdMap.get(oli.Id) != null && oppProdMap.get(oli.Id) != '')
                {
                    if(oli.Discount != decimal.valueOf(oppProdMap.get(oli.Id)))
                    {                    
                        discountedProducts += oli.Name + ', ';
                        oli.Discount = decimal.valueOf(oppProdMap.get(oli.Id));
                    }
                }
                else                
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please make sure each of the discount fields has a value.'));                
            }
            
            if(discountedProducts != '')
            {
                update oliList; 
                
                generateProductList(oppId);
                
                discountedProducts = discountedProducts.removeEnd(', ');
                discountedProducts += '.';
                
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Discount applied successfuly to all products'));        
        }
    }            
    
    public class ProductOption
    {   
        public string idValue { get; set; }
        
        public string value { get; set; }
        
        public string label { get; set; }
        
        public string quantity { get; set; }
        
        public string total { get; set; }
        
        public string discount { get; set; }        
        
        public ProductOption(string v, string l, string i, string q, string t, string d)
        {	
            label = l;
            
            idValue = i;
            
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
}