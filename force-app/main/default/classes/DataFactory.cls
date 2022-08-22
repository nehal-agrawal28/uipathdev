/**
*
* Author:       Daniel Sarchiz
* Date:         11/11/2017
* Description:  Class used to create data in unit tests
* Revision: #1 - added method for order and order item creation
*
**/
@isTest
public with sharing class DataFactory {
    
    public static Account createAccount(String recordTypeName, Boolean insertFlag) {
        
        Account newAccount = new Account();
        
        newAccount.Name = 'Test' + String.valueOf(System.now());
        newAccount.RecordTypeId = Utilities.getRecordTypeId(recordTypeName, 'Account');
        newAccount.BillingStreet = 'Test Street';
        newAccount.BillingCity = 'Test City';
        newAccount.BillingPostalCode = '123456';
        newAccount.BillingCountry = 'United Kingdom';
        newAccount.Phone = '12345678';
        newAccount.Industry = 'Others';
        newAccount.PO_Mandatory__c = 'Yes';
        newAccount.Courier__c = 'No';
        newAccount.Platform__c = 'No';
        newAccount.CSM__c = [Select id from User where Profile.Name = 'Customer Success Manager' and isactive=true limit 1].Id;
        if(insertFlag) {
            
            insert newAccount;
        }
        
        return newAccount;
    }
    
    public static Contact createContact(Id accountId, Boolean insertFlag) {
        
        Contact newContact = new Contact();
        
        newContact.AccountId = accountId;
        newContact.FirstName = 'Test';
        newContact.LastName = String.valueOf(System.now());
        newContact.Email = 'test123123asd@asdawe.com';
        newContact.Title = 'Title';
        newContact.Department__c = 'IT';
        
        if(insertFlag) {
            
            insert newContact;
        }
        
        return newContact;
    }
    
    public static Opportunity createOpportunity(Id accountId, Boolean insertFlag) {
        
        Opportunity newOpportunity = new Opportunity();
        
        newOpportunity.AccountId = accountId;
        newOpportunity.Name = 'Test' + String.valueOf(System.now());
        newOpportunity.StageName = Constants.OPPORTUNITY_STAGE_DISCOVERY;
        newOpportunity.CloseDate = System.today();
        newOpportunity.Type = Constants.OPPORTUNITY_TYPE_1;
        newOpportunity.Led_by__c = Constants.OPPORTUNITY_LED_BY_1;
        newOpportunity.Won_Reasons__c = Constants.OPPORTUNITY_REASON_3;
        newOpportunity.Features_the_customer_liked_didn_t_like__c = 'The best products are here';
        newOpportunity.Name_of_competition_last_round__c = 'We are our own competition';
        newOpportunity.Name_of_our_partner__c = 'The best partner';
        newOpportunity.UiPath_team_part_of_the_bid_process__c = 'The whole company';
        newOpportunity.Closeout_Reason__c = 'We Won the account today!';   
        newOpportunity.CurrencyIsoCode = 'USD';
        newOpportunity.Opportunity_Vertical__c  = Constants.OPPORTUNITY_VERTICAL_1;
        newOpportunity.LeadSource = 'Partner';
        newOpportunity.Deal_Type__c = Constants.OPPORTUNITY_DEALTYPE_DIRECT;


        if(insertFlag) {
            
            insert newOpportunity;
        }
        
        return newOpportunity;
    }


    public static SBQQ__Quote__c createCPQQuote(Id accountId, Id opportunityId, Boolean insertFlag) {

        SBQQ__Quote__c quote = new SBQQ__Quote__c(  SBQQ__Opportunity2__c = opportunityId,
                                                    SBQQ__Account__c = accountId,
                                                    CurrencyIsoCode = 'USD',
                                                    SBQQ__StartDate__c = System.today(),
                                                    SBQQ__EndDate__c = System.today().addMonths(1));

        if(insertFlag) {
            insert quote;
        }

        return quote;
    }



    public static Case createCase(Id accountId, Id contactId, Id opportunityId, Boolean insertFlag) {
        
        Case newCase = new Case();
        
        newCase.AccountId = accountId;
        newCase.ContactId = contactId;
        newCase.Opportunity__c = opportunityId;
        newCase.UiPath_Inc_Signer__c = Constants.CASE_UIPATH_SIGNER_FIRST_NAME_2 + ' ' + Constants.CASE_UIPATH_SIGNER_LAST_NAME_2;
        newCase.UiPath_Inc_Signer_Title__c = Constants.CASE_UIPATH_SIGNER_TITLE_2;
        newCase.UiPath_Srl_Signer__c = Constants.CASE_UIPATH_SIGNER_FIRST_NAME_1 + ' ' + Constants.CASE_UIPATH_SIGNER_LAST_NAME_1;
        newCase.UiPath_Srl_Signer_Title__c = Constants.CASE_UIPATH_SIGNER_TITLE_1;
        newCase.RecordTypeId = Utilities.getRecordTypeId(Constants.CASE_RECORD_TYPE_1, 'Case');

        if(insertFlag) {
            
            insert newCase;
        }
        
        return newCase;
    }
    
    public static User createUser(String firstName, String lastName, String profileName, Boolean insertFlag) {
        
        User newUser = new User();
        
        newUser.ProfileId = [SELECT Id FROM Profile WHERE Name =: profileName].Id;
        newUser.firstName = firstName;
        newUser.lastName = lastName;
        newUser.Email = String.valueOf(firstName + lastName + '@test.uipath').replaceAll( '\\s+', '');
        newUser.Username = String.valueOf(firstName + lastName + '@test.uipath').replaceAll( '\\s+', '');
        newUser.CompanyName = 'Test';
        newUser.Title = 'Title';
        newUser.Alias = 'Alias';
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.EmailEncodingKey = 'UTF-8';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        
        if(insertFlag) {
            
            insert newUser;
        }
        
        return newUser;
    }
    
    public static ContentVersion createFile(String fileName, Id relatedRecordId, String shareType, Boolean insertFlag) {
        
        ContentVersion newContentVersion = new ContentVersion();
        
        newContentVersion.Title = fileName;
        newContentVersion.PathOnClient = 'Test_Document.pdf';
        newContentVersion.VersionData = Blob.valueOf('Test Content');
        newContentVersion.IsMajorVersion = true;
        
        if(insertFlag) {
            
            insert newContentVersion;
            
            ContentDocument newContentDocument = [SELECT Id FROM ContentDocument WHERE Title =: fileName LIMIT 1];
            
            if(String.isNotEmpty(relatedRecordId) && newContentDocument != null) {
                
                createFileLink(relatedRecordId, newContentDocument.Id, shareType, true);
            }
            
            newContentVersion = [SELECT ContentDocumentId, Title, PathOnClient, VersionData, IsMajorVersion FROM ContentVersion WHERE Id =: newContentVersion.Id];
        }
        
        return newContentVersion;
    }
    
    public static ContentDocumentLink createFileLink(Id relatedRecordId, Id relatedContentDocumentId, String shareType, Boolean insertFlag) {
        
        ContentDocumentLink newContentDocumentLink = new ContentDocumentLink();
        
        newContentDocumentLink.LinkedEntityId = relatedRecordId;
        newContentDocumentLink.ContentDocumentId = relatedContentDocumentId;
        newContentDocumentLink.shareType = shareType;
        
        if(insertFlag) {
            
            insert newContentDocumentLink;
        }
        
        return newContentDocumentLink;
    }
    
    public static Attachment createAttachment(String attachmentName, Id parentRecordId, Boolean insertFlag) {
        
        Attachment newAttachment = new Attachment();
        
        newAttachment.Name = attachmentName;
        newAttachment.body = Blob.valueOf('Unit Test Attachment Body');
        newAttachment.ParentId = parentRecordId;
        
        if(insertFlag) {
            
            insert newAttachment;
        }
        
        return newAttachment;
    }



    public static List<Address__c> createAddress(integer numberOfRecords, id accountId, boolean insertFlag) {

        List<Address__c> addresses = new List<Address__c>();

        for(integer i =0; i<numberOfRecords; i++){
            Address__c addObj = new Address__c(
                    Street_Line_1__c = 'Test Street Line 1'+i,
                    Street_Line_2__c = 'Test Street Line 2'+i,
                    City__c = 'London',
                    State__c = 'England',
                    Country__c = 'United Kingdom',
                    Zip_Postal_Code__c = '416778',
                    Account__c = accountId,
                    Validation_Status__c = 'Pending' );

            addresses.add(addObj);
        }

        if(insertFlag){
            insert addresses;
        }

        return addresses;
    }
    
    public static dsfs__DocuSign_Status__c createDocuSignStatusQuote(Id accountId, Id opportunityId, Id caseId, Id quoteId, Boolean insertFlag) {
        
        dsfs__DocuSign_Status__c newDocuSignStatus = new  dsfs__DocuSign_Status__c();
        
        newDocuSignStatus.dsfs__Company__c = accountId;
        newDocuSignStatus.dsfs__Opportunity__c = opportunityId;
        newDocuSignStatus.dsfs__Case__c = caseId;
        newDocuSignStatus.Quote__c = quoteId;
        newDocuSignStatus.dsfs__Envelope_Status__c = Constants.DOCUSIGN_ENVELOPE_STATUS_1;
        newDocuSignStatus.dsfs__DocuSign_Envelope_ID__c = '1001A123-1234-5678-1D84-F8D44652A382';
        newDocuSignStatus.dsfs__Subject__c = 'Document for eSignature';
        
        if(insertFlag) { 
            
            insert newDocuSignStatus;
        }
        
        return newDocuSignStatus;
    }
    
    public static dsfs__DocuSign_Status__c createDocuSignStatus(Id accountId, Id opportunityId, Id caseId, Boolean insertFlag) {
        
        dsfs__DocuSign_Status__c newDocuSignStatus = new  dsfs__DocuSign_Status__c();
        
        newDocuSignStatus.dsfs__Company__c = accountId;
        newDocuSignStatus.dsfs__Opportunity__c = opportunityId;
        newDocuSignStatus.dsfs__Case__c = caseId;
        newDocuSignStatus.dsfs__Envelope_Status__c = Constants.DOCUSIGN_ENVELOPE_STATUS_1;
        newDocuSignStatus.dsfs__DocuSign_Envelope_ID__c = '1001A123-1234-5678-1D84-F8D44652A382';
        newDocuSignStatus.dsfs__Subject__c = 'Document for eSignature';
        
        if(insertFlag) { 
            
            insert newDocuSignStatus;
        }
        
        return newDocuSignStatus;
    }
    
    public static DocuSign_Settings__c createDocusignSettings() {
        
        DocuSign_Settings__c newDocuSignSettings;
        
        newDocuSignSettings = new DocuSign_Settings__c(Integration_User_Id__c = UserInfo.getUserId().substring(0, 15));
        
        insert newDocuSignSettings;
        
        return newDocuSignSettings;
    }

    public static Product2 createProduct(Boolean isInsert){
        Product2 prod = new Product2(
            Name = 'UiPath - Orchestrator - Standard',             // Product Name
            Family = 'Core Product',                               // Product Family
            NS_Item_Name__c = 'UiPath - Orchestrator - Standard',  // NS Item Name
            ProductCode = 'UIPCPOSE000',                           // Product Code
            IsActive = true,                                       // Active
            License_Model__c = 'Server',                           // License Model
            Unit_of_measure__c = 'Each/User per year',             // Unit of measure
            Orderable__c = true,                                   // Orderable
            Vendor__c = 'UiPath',                                  // Vendor
            Description = 'Robot Management ',
            Sync_Status__c = 'Synced',                             // Sync Status
            NS_Item_Internal_ID__c = '1365',                       // NS Item Internal ID
            SBQQ__PricingMethod__c = 'List',                       // Pricing Method
            SBQQ__SubscriptionPricing__c = 'Fixed Price',          // Subscription Pricing
            SBQQ__SubscriptionTerm__c = 12,                        // Subscription Term
            SBQQ__SubscriptionCategory__c = 'Platform Core',       // Percent Of Total Category
            SBQQ__SubscriptionBase__c = 'List',                    // Percent Of Total Base
            SBQQ__SubscriptionType__c = 'Renewable'                // Subscription Type
        );
        if(isInsert){
            insert prod;
        }
        return prod;  
    }

    public static PricebookEntry createStdPricebookEntry(Id prodId, Decimal unitPrice, Boolean isInsert){
        PricebookEntry pbe = new PricebookEntry(              
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prodId,
            UnitPrice = unitPrice,
            IsActive = true
        );
        if(isInsert){
            insert pbe;
        }
        return pbe;
    }

    public static SBQQ__QuoteLine__c createCPQQuoteLine(Id productId, Id quoteId, Boolean isInsert){
        SBQQ__QuoteLine__c line = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteId,                                // Quote
            SBQQ__Product__c = productId,                            // Product
            SBQQ__Quantity__c = 1.00,                                // Quantity
            Unit_of_measure__c = 'Each/User per year',               // Unit of measure
            SBQQ__PricingMethod__c = 'List',                         // Pricing Method
            Business_Type__c = 'New Business',                       // Business Type
            Line_Product_Family__c = 'UiPath',                       // Line Product Family
            Product_Version__c = '2019.10',                          // Product Version
            License_Model__c = 'Server',                             // License Model
            SBQQ__ListPrice__c = 20000.00,                           // List Unit Price
            SBQQ__CustomerPrice__c = 5000.00,                        // Customer Unit Price
            SBQQ__NetPrice__c = 5000.00,                             // Net Unit Price
            SBQQ__SpecialPrice__c = 20000.00,                        // Special Price
            SBQQ__RegularPrice__c = 20000.00,                        // Regular Unit Price
            SBQQ__ProratedListPrice__c = 20000.00,                   // Prorated List Price
            SBQQ__SubscriptionPricing__c = 'Fixed Price',            // Subscription Pricing
            SBQQ__SubscriptionScope__c = 'Quote',                    // Percent of Total Scope
            SBQQ__SubscriptionBase__c = 'List',                      // Percent of Total Base
            SBQQ__DefaultSubscriptionTerm__c = 12                    // Default Subscription Term
        );
        if(isInsert){
            insert line;
        }
        return line;
    }

    public static Quote_Approval_Matrix__c createQuoteApprovalMatrix(String geo, String approverId, 
                                                                        String type, String role, 
                                                                        String region, String area, Boolean isInsert){
        Quote_Approval_Matrix__c matrix = new Quote_Approval_Matrix__c(
            Geo__c = geo,
            Approver__c = approverId,
            Type__c = type,
            Role__c = role,
            Region__c = region,
            Area__c=area
        );
        if(isInsert){
            insert matrix;
        }
        return matrix;
    }

    public static Billing_Segment__c createBillingSegment( Id quoteId,Decimal segmentNum,Decimal amount,Boolean isInsert){
        Billing_Segment__c sobj = new Billing_Segment__c(
            Name = 'Billing Period 1',                 // Billing Segment Name
            Segment_No__c = segmentNum,                         // Segment Number
            Start_Date__c = Date.valueOf('2020-12-01'),  // Start Date
            End_Date__c = Date.valueOf('2021-11-30'),    // End Date
            Duration__c = 365,                         // Duration
            Total_Amount__c = amount,                  // Total Amount
            Quote__c = quoteId                // Quote
        );
        if(isInsert){
            insert sobj;
        }
        return sobj;

    }


    /**
     * Used in tests that need a random Quote with an associated Opp and Account etc.
     * Any overrides to all the defaults in this method can be done in the corresponding test method.
     * @param testIdentifier used to avoid any contention issues by making sure the same names aren't used
     */
    public static SBQQ__Quote__c createSampleQuoteWithAssociations(String testIdentifier){

        String accountRef=String.valueOf(Math.random() *100000);
        Account account1 = new Account(
                Name = testIdentifier,
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Constants.ACCOUNT_RECORD_TYPE_1).getRecordTypeId(),
                Legal__c = testIdentifier,
                Overwrite_Legal_Entity_Name__c = true,
                Country__c = 'Australia',
                State__c = 'Victoria',
                Meets_CSM_Criteria__c = 'No',
                Website = 'http://www.' + testIdentifier + '.com',
                Phone = '+61 3 9905 5054',
                Classification__c = 'Enterprise',
                Industry = 'Education',
                Maintenance_Flag__c = 'Premium',
                Premium_End_Date__c = Date.newInstance(System.today().year() + 1, System.today().month(), 27),
                Geo__c = 'APJ',
                Region__c = 'ANZ',
                Ignore_Territory_Assignment__c = false,
                Academic_Alliance_Agreement__c = false,
                AnnualRevenue = 1828768130.00,
                Overwrite_Annual_Revenue__c = false,
                Revenue_Source__c = 'Dun & Bradstreet',
                SBQQ__IgnoreParentContractedPrices__c = true,
                NumberOfEmployees = 14318,
                Active_Account__c = false,
                Domain__c = testIdentifier+'.edu',
                Matched_with_D_B__c = 'Matched',
                Verified_by_Data_Steward__c = 'Verified',
                Overwrite_Billing_Address__c = false,
                Default_Payment_Terms__c = '30 Days Net',
                Sync_Status__c = 'Synced',
                Primary_Subsidiary__c = 'UiPath SRL',
                Channel_Tier__c = 'End User',
                NS_Customer_Internal_ID__c = accountRef,
                Validation_Status__c = 'Validated',
                NetSuite_Customer__c = accountRef,
                Receivables__c = 251381.02,
                PO_Mandatory__c = 'No',
                Courier__c = 'No',
                Platform__c = 'No',
                KomikoId__c= testIdentifier
        );
        Database.upsert(account1,Account.KomikoId__c);


        Contact primaryContact = new Contact(
                AccountId = account1.Id,
                LastName = testIdentifier,
                FirstName = 'John',
                LeadSource = 'Website - Direct',
                Email = 'test.' + testIdentifier + '@test.edu',
                First_referring_site__c = 'https://www.uipath.com/contact-us',
                HasOptedOutOfEmail = false,
                Direct_Phone__c = '+61 03 9905 9697',
                Last_Activity_Made_by_Sales__c = '0',
                Lifecycle_Stage__c = 'Opportunity',
                Original_Source__c = 'Referrals',
                Send_Welcome_Letter_c__c = false,
                Original_Source_drill_down_1__c = 'www.uipath.com/contact-sales-partnerships',
                Academic_Alliance_Agreement__c = false,
                Recent_Website_Conversion__c = 'Start Free Trial Studio Pro Request',
                Personal_Contact_Notes__c = '',
                Academy_Registration_Date__c = Date.valueOf('2018-08-22'),
                KomikoId__c=testIdentifier,
                Department__c = 'IT'

        );
        Database.upsert(primaryContact,Contact.KomikoId__c);


        Opportunity opportunity = new Opportunity(
                Name = testIdentifier + ' Multi Year Deal',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CPQ Default').getRecordTypeId(),
                AccountId =[Select Id from Account where KomikoId__c=:testIdentifier].Id,
                Deal_Type__c = 'Direct',
                Led_by__c = 'Partner Led',
                Must_Win__c = false,
                Managing_Director__c = UserInfo.getUserId(),
                LeadSource = 'Website - Direct',
                SBQQ__Contracted__c = false,
                SBQQ__Renewal__c = false,
                Deal_Reg_Status__c = 'Approved',
                Deal_Reg_Notes_Comments__c = '14Oct19RP: Deal Registration through the partner RPA Solutions ',
                Influence__c = 'RPA Solutions Australia Pty Ltd',
                StageName = 'Discovery',
                CloseDate = Date.newInstance(2020, 3, 11),
                Opportunity_Next_Steps__c = 'Marking as Closed Won Pending.',
                Positive_Business_Outcomes__c = 'Student Experience, Staff Engagement, Research',
                Value_Drivers__c = 'Accelerate Benefits from Digital Transformation; Improve Customer Experience; ' +
                        'Improve Employee Experience; Improve Compliance',
                Competition__c = 'Automation Anywhere; Blue Prism',
                Paper_Process__c = 'Paperwork to come today as per last comms from client.',
                Decision_Process_Actual__c = 'Decision has already been made to go UiPath',
                Won_Reasons__c = 'Product roadmap',
                Closeout_Reason__c = 'As above As above As above',
                Features_the_customer_liked_didn_t_like__c = 'Not applicable Not applicable',
                Send_invoice_to__c = 'mel.Vanroyen@test.com',
                Customer_Primary_Contact__c = [Select Id from Contact where KomikoId__c=:testIdentifier].Id,
                Send_licenses_to__c = 'mel.vanroyen@test.com',
                Payment_Cycle__c = 'Annual',
                Termination_Clause__c = 'No',
                Contract_Start_Date__c = Date.newInstance(System.today().year(), System.today().month(), 28),
                Contract_End_Date__c = Date.newInstance(System.today().year() + 3, System.today().month(), 27)
        );
        insert opportunity;


        OpportunityContactRole opportunityContactRoleTechBuyer = new OpportunityContactRole(ContactId = [Select Id from Contact where KomikoId__c=:testIdentifier].Id,
                IsPrimary = true,
                OpportunityId = opportunity.Id,
                Role = 'Technical Buyer');

        insert opportunityContactRoleTechBuyer;


        SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opportunity.Id,
                SBQQ__Primary__c = true,
                SBQQ__Account__c = [Select Id from Account where KomikoId__c=:testIdentifier].Id,
                Bill_To_Account__c = [Select Id from Account where KomikoId__c=:testIdentifier].Id,
                SBQQ__PrimaryContact__c = [Select Id from Contact where KomikoId__c=:testIdentifier].Id,
                SBQQ__Type__c = 'Quote',
                SBQQ__Status__c = 'Draft',
                Payment_Terms__c = '30 Days Net',
                SBQQ__StartDate__c = Date.newInstance(System.today().year(), System.today().month(), 28),
                SBQQ__EndDate__c = Date.newInstance(System.today().year() + 3, System.today().month(), 27),
                SBQQ__ExpirationDate__c = System.today().addDays(30),
                RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('CPQ Default').getRecordTypeId(),
                External_Ref__c=testIdentifier
        );
        insert quote;

        return quote;
    }

    public static Order createOrder(Id quoteId, Id opportunityId, Boolean insertFlag) {
        Order order = new Order(
            SBQQ__Quote__c = quoteId, 
            OpportunityId = opportunityId,
            Status = Constants.DRAFT_ORDER_STATUS,
            EffectiveDate = System.today());

        if(insertFlag){
            insert order;
        }
        return order;
    }

    public static OrderItem createOrderItem(Id orderId, Id pbeId, Boolean insertFlag) {
        OrderItem orderItem = new OrderItem(
            OrderId = orderId, 
            PricebookEntryId = pbeId,
            Quantity = 1,
            UnitPrice = 100);

        if(insertFlag){
            insert orderItem;
        }
        return orderItem;
    }

    public static SBQQ__Dimension__c createPriceDimension(Id productId, Boolean insertFlag){
        SBQQ__Dimension__c priceDimension = new SBQQ__Dimension__c(
            Name = 'Test' + String.valueOf(System.now()),
            SBQQ__Product__c = productId,
            SBQQ__Type__c = 'Year'
        );

        if(insertFlag){
            insert priceDimension;
        }
        return priceDimension;
    }

    public static Contract createContract(Id accountId, Boolean insertFlag){
        Contract testContract = new Contract(
            Name = 'Test' + String.valueOf(System.now()),
            AccountId = accountId
        );

        if(insertFlag){
            insert testContract;
        }
        return testContract;
    }
}