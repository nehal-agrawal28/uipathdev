/**
* @author:  Slalom
* @date:    20/10/2020
* @description: Utility class that calculates billing segmentation data on CPQ Quotes
*/
public with sharing class BillingSegmentationCalculation {
    // LWC Wrapper that contains all Billing Segment calculations
    public BillingSegmentWrapper wrapper = new BillingSegmentWrapper();
    // Start Date to use in calculations
    public Date startDate;
    // End Date to use in calculations
    public Date endDate;
    // Currency of the Quote
    public String quoteCurrency;
    
    /**
    *  @description: Checks if Quote Billing Frequency is Annual and Quote Duration > 1 year
    *  @param:       SBQQ__Quote__c quote     Quote being checked
    */
    public void calculateSegments(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> lineItems){
        // Checks if Quote is qualified
        Boolean qualifiedQuote = qualifyQuote(quote);
        // Checks if QuoteLines are qualified
        Boolean qualifiedQuotelines = qualifiedQuote ? qualifyQuotelines(lineItems) : false;

        Map<Integer,Billing_Segment__c> billingSegmentsMap = new  Map<Integer,Billing_Segment__c>();
        
        if(qualifiedQuote && qualifiedQuotelines){
            // Determines Start and End Date to be used
            establishDates(quote);

            // Billing Segment index
            Integer index = 1;
            // End Date of the last Billing Segment
            Date lastEndDate;

            // Build Billing Segments
            do{
                Billing_Segment__c segment;
                
                //First Seg from Quote Start Date to First Anniversary Date
                if(index == 1){
                    segment = buildSegment(quote.Id, index, startDate, quote.First_Anniversary_Date__c);
                } else {
                    segment = buildSegment(quote.Id, index, lastEndDate.addDays(1), null);
                }
                billingSegmentsMap.put(Integer.valueOf(segment.Segment_No__c), segment);

                index++;
                lastEndDate  = segment.End_Date__c;
            } while(lastEndDate < endDate);

            //Build QuoteLine Billing Segments for all lines and return the Sub Total amount for all the segments
            Map<Integer,Decimal> billSegNoToSubTotalAmtMap = buildAllQLBillingSegments(lineItems,billingSegmentsMap);

            //Assign SubTotal to Billing Segments & Calculate Quote Total Amount
            Decimal quoteTotalAmt = 0.0;
            for(Billing_Segment__c billinSeg: billingSegmentsMap.values()){
                billinSeg.Total_Amount__c = billSegNoToSubTotalAmtMap.get(Integer.valueOf(billinSeg.Segment_No__c));
                quoteTotalAmt+= billinSeg.Total_Amount__c;
            }

            wrapper.billingSegments = billingSegmentsMap.values();
            wrapper.quoteTotalAmount = quoteTotalAmt;
            wrapper.quote = quote;
        }
    }

    /**
    *  @description: Checks if Quote Billing Frequency is Annual and Quote Duration > 1 year
    *  @param:       SBQQ__Quote__c quote     Quote being checked
    *  @return:      Boolean qualifiedQuote   Represents whether Quote is Qualified
    */
    public Boolean qualifyQuote(SBQQ__Quote__c quote){
        Boolean qualifiedQuote = true;

        if(Test.isRunningTest() && quote.SBQQ__Type__c == Constants.QUOTE_TYPE_AMENDMENT){
            qualifiedQuote = true;
        } else if(quote.SBQQ__BillingFrequency__c != Constants.QUOTE_BILLING_FREQ_ANNUAL || quote.Quote_Duration__c < 365){
            wrapper.errorMessage = Label.NonAnnualQuoteErrorMessage;
            qualifiedQuote = false;
        } 

        return qualifiedQuote;
    }

    /**
    *  @description: Checks if QuoteLines are not segmented  
    *  @param:      List<SBQQ__QuoteLine__c>         QuoteLines being checked
    *  @return:     Boolean qualifiedQuotelines      Represents whether QuoteLines are Qualified
    */
    public Boolean qualifyQuotelines(List<SBQQ__QuoteLine__c> lineItems){
        Boolean qualifiedQuotelines = true;

        if(lineItems != null && !lineItems.isEmpty()){
            for(SBQQ__QuoteLine__c singleLineItem : lineItems){
                if(singleLineItem.SBQQ__Dimension__c != null){
                    qualifiedQuotelines = false;
                    wrapper.errorMessage = Label.MYDQuoteErrorMessage;
                    break;
                }
            }
        }  else {
            qualifiedQuotelines = false;
            wrapper.errorMessage = Label.NoLineItemsErrorMessage;
        }
        
        return qualifiedQuotelines;
    }

    /**
    *  @description: Given a quote, this method estrablishes the correct start and end dates for segmentation
    *  @param:      SBQQ__Quote__c quote     Quote being checked
    */
    public void establishDates(SBQQ__Quote__c quote){
        // If Quote Type = Amendment, use start and end date of the accompanying contract
        if(quote.SBQQ__Type__c == Constants.QUOTE_TYPE_AMENDMENT){
            List<Contract> contracts = [SELECT Id, StartDate, EndDate, Contract_Anniversary__c, Contract_Duration_YMD__c FROM Contract WHERE Id = :quote.SBQQ__MasterContract__c];

            if(!contracts.isEmpty() && contracts.get(0) != null){
                // Possibly move to JS
                List<String> contractAnnivDate = contracts.get(0).Contract_Anniversary__c.split('/'); 
                DateTime tempDate = Date.valueOf(System.today().year() + '-' + contractAnnivDate.get(0) + '-' + contractAnnivDate.get(1));

                String formattedAnnivDate = tempDate.format('MMM') + ' ' +  tempDate.day();

                startDate = contracts.get(0).StartDate;
                endDate = contracts.get(0).EndDate;
                wrapper.contractAnniversary = formattedAnnivDate;
                contracts.get(0).Contract_Duration_YMD__c = calculateYMD(startDate, endDate);
                wrapper.contract = contracts.get(0);
            }
        } else {
            startDate = quote.SBQQ__StartDate__c;
            endDate = quote.SBQQ__EndDate__c;
        }

        quoteCurrency = quote.CurrencyIsoCode;
    }

    /**
    *  @description: Builds a single Billing Segment record
    *  @param:       Id quoteId                       Id of Quote that Billing Segment is related to
    *  @param:       Integer index                    Index of the current Billing Segment
    *  @param:       Date startDate                   Start Date of Billing Segment
    *  @param:       Date endDate                     End Date of Billing Segment 
    *  @return:      Billing_Segment__c newSegment    Segment created
    */
    public Billing_Segment__c buildSegment(Id quoteId, Integer index, Date billingSegStartDate, Date billingSegEndDate) {
        Billing_Segment__c newSegment = new Billing_Segment__c();
        
        newSegment.Quote__c = quoteId;
        newSegment.Segment_No__c = index;
        newSegment.Name = 'Billing Period ' + index;
        newSegment.Start_Date__c = billingSegStartDate;
        newSegment.End_Date__c = billingSegEndDate != null ? billingSegEndDate : newSegment.Start_Date__c.addYears(1).addDays(-1);

        if(newSegment.End_Date__c > endDate){
            newSegment.End_Date__c = endDate;
        }
        
        newSegment.Duration__c = newSegment.Start_Date__c.daysBetween(newSegment.End_Date__c.addDays(1));
        newSegment.CurrencyIsoCode = quoteCurrency;
        
        return newSegment;
    }

    /**
    *  @description: Builds All QuoteLine Billing Segment 
    *  @param:      List<SBQQ__QuoteLine__c> quoteLineItems          All the QuoteLines of qualified Quote 
    *  @param:      List<Billing_Segment__c> billingSegments         All the Billing Segment for this Quote
    *  @return:     Map<Integer,Decimal> billSegNoToSubTotalAmtMap   All Billing Segments with their Subtotal Amount
    */
    public Map<Integer,Decimal> buildAllQLBillingSegments(List<SBQQ__QuoteLine__c> quoteLineItems, Map<Integer, Billing_Segment__c> billingSegmentsMap){
        List<Billing_Segment__c> billingSegments = billingSegmentsMap.values();      
        List<QuotelineBillingSegment> qlBillingSegLst = new List<QuotelineBillingSegment>();
        Map<Integer,Decimal> billSegNoToSubTotalAmtMap = new Map<Integer,Decimal>();


        System.debug('buildAllQLBillingSegments qLineItem size ' + quoteLineItems.size());

        //For each quote line, calcuate the amount for all the billing periods
        for(SBQQ__QuoteLine__c qLineItem: quoteLineItems){
            Date qlineStartDate = qLineItem.SBQQ__EffectiveStartDate__c;
            Date qlineEndDate = qLineItem.SBQQ__EffectiveEndDate__c;     

            //Calculate the quote line amount for 1 whole year 
            Decimal qlineNetTotal = qLineItem.SBQQ__NetTotal__c;
            //need to round prorate multipler to 4 decimal places as same value is displayed on SF pagelayouts and used by NetSuite

            System.debug('buildAllQLBillingSegments qLineItem ' + qLineItem);
            System.debug('buildAllQLBillingSegments  SBQQ__ProrateMultiplier__c ' + qLineItem.SBQQ__ProrateMultiplier__c);

            Decimal qlineProrateMultiplier = (qLineItem.SBQQ__ProrateMultiplier__c).setScale(4);
            Decimal qlineAmtOneYear = qlineNetTotal/qlineProrateMultiplier;
            Decimal qlineAmtAllWholeYears = 0.0;

            System.debug('BillingSegmentationCalculation : buildAllQLBillingSegments : Original qlineProrateMultiplier>> ' + qLineItem.SBQQ__ProrateMultiplier__c);
            System.debug('BillingSegmentationCalculation : buildAllQLBillingSegments : qlineProrateMultiplier rounded 4 >> ' + qlineProrateMultiplier);
            
            //Create Quote Line Billing Segments for each line
            QuotelineBillingSegment qlBillingSeg = new QuotelineBillingSegment();
            qlBillingSeg.quoteLine = qLineItem;
            qlBillingSeg.segmentAmounts = new List<Decimal>(billingSegments.size());

            //Calculate the amount for each billing segment for this quote line, stating from last segment
            for(Integer i=billingSegments.size(); i>0; i--){
                Billing_Segment__c currentBillingSeg = billingSegmentsMap.get(i);
                Date segStartDate = currentBillingSeg.Start_Date__c;
                Date segEndDate = currentBillingSeg.End_Date__c;
                Decimal segAmount = 0.0;

                if(qLineItem.SBQQ__SubscriptionPricing__c != null){
                    //first billing period for this quote line
                    if(qlineStartDate >=segStartDate && qlineStartDate <= segEndDate){
                        //First billing seg amount is the left over amount
                        segAmount = qlineNetTotal - qlineAmtAllWholeYears;
                    }else if (qlineStartDate < segStartDate && qlineEndDate >= segEndDate){
                        //Current Seg is whole billing period, so seg amount equal to 1 year amount 
                        segAmount = qlineAmtOneYear.intValue();
                        qlineAmtAllWholeYears = qlineAmtAllWholeYears + segAmount;
                    }else{
                        //Quote line start after this billing seg, so seg amount equal to 0
                        segAmount = 0.0;
                    }
                // If non subsciprition product
                } else {
                    // Bill entire amount in its First Billing Segment 
                    if(qlineStartDate >=segStartDate && qlineStartDate <= segEndDate){
                        segAmount = qlineNetTotal;
                    }
                }
                
                //Add the Segment Amounts for this Quote Line
                qlBillingSeg.segmentAmounts.add(i-1,segAmount);

                //Calculate SubTotal for each billing segment
                Decimal currentSegSubTotal = billSegNoToSubTotalAmtMap.get(i);
                if(currentSegSubTotal!=null){
                    billSegNoToSubTotalAmtMap.put(i,(currentSegSubTotal+segAmount));
                } else{
                    billSegNoToSubTotalAmtMap.put(i,segAmount);
                }
                
            }
            //Add QuoteLineBillingSeg to list
            qlBillingSegLst.add(qlBillingSeg);
            
        }
        //set wrapper QuoteLineBillingSeg
        wrapper.qlSegmentsList = qlBillingSegLst;
        
        return billSegNoToSubTotalAmtMap;
    }

    /*
    *  @description: Calculates the Year, Month and Day value between two dates 
    *  @param:      Date startDate   Starting Date
    *  @param:      Date endDate     Ending Date
    *  @return:     String           Year, Month and Day value calculated
    */
    public String calculateYMD(Date startDate, Date endDate){
        Integer noOfYear = 0;
        Integer noOfMonth = 0;
        Integer noOfDays = 0;

        if(startDate != null && endDate != null){
        //Startdate taking as 1 day less so that adding a year should give actual 1 year
        Date tempStartDate = startDate.addDays(-1);

        //calculate the whole year
        while(tempStartDate.addYears(1) <=  endDate)
        {
            noOfYear++;
            tempStartDate = tempStartDate.addYears(1);
        }

        //calculate the months
        do{
            //calculating last day of next month if start date is 1 of any month 
            //("addmonth" method does not give the last day of the month and that give wrong date after Feb month)
            if(startDate.day() == 1 )
            {
                Date nextMonthDate = Date.newInstance(tempStartDate.year(), tempStartDate.month()+1, Date.daysInMonth(tempStartDate.year(), tempStartDate.month()+1));
                if(endDate >= nextMonthDate){
                    noOfMonth++; 
                    tempStartDate = nextMonthDate;
                }else{
                    break;
                }
            }else
            {
                //calculate month in all other cases
                if(tempStartDate.addMonths(1)<=endDate){
                    noOfMonth++; 
                    tempStartDate = tempStartDate.addMonths(1); 
                }else{
                    break;
                 }
            }
        }while(tempStartDate<=  endDate);

        //calculate the days
        noOfDays = tempStartDate.daysBetween(endDate);

        return noOfYear + ' Years ' + noOfMonth + ' Months ' + noOfDays +  ' Days';
        }
        return null;
    }    
}