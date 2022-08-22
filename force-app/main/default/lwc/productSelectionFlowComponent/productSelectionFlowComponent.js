import { LightningElement, api, track } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';

// Apex Methods
import createDealRegWithProductsApex from '@salesforce/apex/ProductSelectionController_PP.createDealRegWithProducts';

// Custom Labels
import CREATE_DRAFT from '@salesforce/label/c.Create_Draft';

export default class ProductSelectionFlowComponent extends LightningElement
{
    customLabels = {
        CREATE_DRAFT
    };

    @track m_AccountId;
    @track m_CampaignId;
    @track m_City;
    @track m_Competition;
    @track m_Country;
    @track m_CurrencyIsoCode;
    @track m_DealRegNotes;
    @track m_DealRegName;
    @track m_DealRegId;
    @track m_DealType;
    @track m_EndCustomerAccountName;
    @track m_EndCustomerWebsite;
    @track m_IsBPO;
    @track m_SalesEmail;
    @track m_SalesPhone;
    @track m_SalesRep;
    @track m_PartnerLeadSource;
    @track noProductSelected = true;
    @track onSelectProductsScreen = true;
    @track onSubmitProductsScreen = false;

    // Getter/Setter
    @api get accountId() { return this.m_AccountId; }
    set accountId(val) { this.m_AccountId = val; }

    @api get campaignId() { return this.m_CampaignId; }
    set campaignId(val) { this.m_CampaignId = val; }

    @api get city() { return this.m_City; }
    set city(val) { this.m_City = val; }

    @api get competition() { return this.m_Competition; }
    set competition(val) { this.m_Competition = val; }

    @api get country() { return this.m_Country; }
    set country(val) { this.m_Country = val; }

    @api get currencyIsoCode() { return this.m_CurrencyIsoCode; }
    set currencyIsoCode(val) { this.m_CurrencyIsoCode = val; }

    @api get dealRegNotes() { return this.m_DealRegNotes; }
    set dealRegNotes(val) { this.m_DealRegNotes = val; }

    @api get dealRegId() { return this.m_DealRegId; }

    @api get dealRegName() { return this.m_DealRegName; }
    set dealRegName(val) { this.m_DealRegName = val; }

    @api get dealType() { return this.m_DealType; }
    set dealType(val) { this.m_DealType = val; }

    @api get endCustomerAccountName() { return this.m_EndCustomerAccountName; }
    set endCustomerAccountName(val) { this.m_EndCustomerAccountName = val; }

    @api get endCustomerWebsite() { return this.m_EndCustomerWebsite; }
    set endCustomerWebsite(val) { this.m_EndCustomerWebsite = val; }

    @api get isBPO() { return this.m_IsBPO; }
    set isBPO(val) { this.m_IsBPO = val; }

    @api get salesEmail() { return this.m_SalesEmail; }
    set salesEmail(val) { this.m_SalesEmail = val; }

    @api get salesPhone() { return this.m_SalesPhone; }
    set salesPhone(val) { this.m_SalesPhone = val; }

    @api get salesRep() { return this.m_SalesRep; }
    set salesRep(val) { this.m_SalesRep = val; }

    @api get partnerLeadSource() { return this.m_PartnerLeadSource; }
    set partnerLeadSource(val) { this.m_PartnerLeadSource = val; }

    @api
    distributorAccountId;

    @api
    resellerAccountId;

    connectedCallback()
    {
        console.log('CurrencyIsoCode', this.currencyIsoCode);
    }

    // Events
    onclickBtnSubmit(event)
    {
        const dealRegProducts = this.template.querySelector('c-product-selection-component').getSelectedProducts();
        if(dealRegProducts.length)
        {
            const dealReg = {
                DealType__c: this.dealType,
                City__c: this.city,
                CloseDate__c: null,
                Competition__c: this.competition,
                Country__c: this.country,
                CurrencyIsoCode: this.currencyIsoCode,
                DealRegNotesComments__c: this.dealRegNotes,
                DealRegistrationAmount__c: null,
                Name: this.dealRegName,
                EndCustomerAccountName__c: this.endCustomerAccountName,
                EndCustomerWebsite__c: this.endCustomerWebsite,
                OwnerId: null,
                PartnerCompanySalesEmail__c: this.salesEmail,
                PartnerCompanySalesPhone__c: this.salesPhone,
                PartnerCompanySalesRep__c: this.salesRep,
                PartnerLeadSource__c: this.partnerLeadSource,
                PriceBook__c: dealRegProducts[0].PricebookId__c
            };

            if (this.distributorAccountId) {
                dealReg.Distributor__c = this.distributorAccountId;
            }

            if (this.resellerAccountId) {
                dealReg.Tier2Partner__c = this.resellerAccountId;
            }

            createDealRegWithProductsApex({
                dealReg: dealReg,
                dealRegProducts: dealRegProducts
            })
            .then(result => {
                if(result)
                {
                    console.log('Deal Reg Id', result);
                    this.m_DealRegId = result;
                    this.isLoaded = true;
                    this.dispatchEvent(new FlowNavigationNextEvent());
                }
                else
                {
                    console.log('Results not true');
                    this.dispatchEvent(new FlowNavigationNextEvent());
                }
            })
            .catch((error) => {
                console.log({error});
            })
        }
    }

    onclickBtnPrevious(event)
    {
        this.dispatchEvent(new FlowNavigationBackEvent());
    }

    onclickBtnNext(event)
    {
        this.template.querySelector('c-product-selection-component').toggleShowSelected();
    }

    onclickBtnBack(event)
    {
        this.template.querySelector('c-product-selection-component').toggleShowSelected();
    }

    processSelectedProductsLength(event)
    {
        this.noProductSelected = (event.detail.selectedProductsLength) ? false : true;
    }

    processShowSelectedChange(event)
    {
        this.onSubmitProductsScreen = event.detail.showSelected;
        this.onSelectProductsScreen = !this.onSubmitProductsScreen;
    }
}