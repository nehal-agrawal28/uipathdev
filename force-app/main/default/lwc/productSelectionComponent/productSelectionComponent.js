import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'

// Apex Methods
import getPricebookEntriesApex from '@salesforce/apex/ProductSelectionController_PP.getPricebookEntries';

// Custom Labels
import PRICE_BOOK_NAME from '@salesforce/label/c.Deal_Reg_Price_Book_Name';

export default class ProductSelectionComponent extends LightningElement
{
    customLabels = {
        PRICE_BOOK_NAME
    };

    @track columns;

    @track columnsSelectedTable;

    @api context;
    @api dealType;
    @api priceBook;
    @api currencyIsoCode;

    products = [];
    numberOfCurrentProducts;
    numberOfVisibleProducts = 100;
    numberOfProductsToLoad = 100;

    @track currentProducts = [];
    @track visibleProducts = [];
    @track selectedProducts = [];
    @track selectedRowIds = [];
    @track selectedProductIds = new Set();
    @track showSelected = false;
    @track isLoaded = false;

    @track errors;

    // Getter/Setter
    get showSelectedButtonLabel()
    {
        if(this.showSelected)
            return 'Back to Results';
        else
            return `Show Selected (${this.selectedProductIds.size})`;
    }

    // Events
    connectedCallback()
    {
        console.log('PriceBook', this.priceBook);
        console.log('CurrencyIsoCode', this.currencyIsoCode);

        this.initColumns();
        this.initPricebookEntries();
    }

    loadMoreData(event)
    {
        event.target.isLoading = true;
        const tempArr = [];
        
        const numberOfTotalProductsToLoad = (this.numberOfVisibleProducts + this.numberOfProductsToLoad);

        if(this.numberOfVisibleProducts != this.numberOfCurrentProducts)
        {
            if(numberOfTotalProductsToLoad < this.numberOfCurrentProducts)
            {
                for(let i = this.numberOfVisibleProducts; i < numberOfTotalProductsToLoad; i++)
                {
                    tempArr.push(this.currentProducts[i]);
                }
                this.numberOfVisibleProducts = numberOfTotalProductsToLoad;
            }
            else
            {
                for(let i = this.numberOfVisibleProducts; i < this.numberOfCurrentProducts; i++)
                {
                    tempArr.push(this.currentProducts[i]);
                }
                this.numberOfVisibleProducts = this.numberOfCurrentProducts
            }
    
            this.visibleProducts = this.visibleProducts.concat(tempArr);
        }
        else
        {
            event.target.enableInfiniteLoading = false;
        }
        event.target.isLoading = false;
    }

    onkeyupInput(event)
    {
        const input = event.target.value.toLowerCase();

        this.currentProducts = this.products.filter(product => {
            return ((this.selectedProductIds.has(product.id)) || (product.name.toLowerCase().includes(input)));
        });

        this.currentProducts.sort((a, b) => {
            if(this.selectedProductIds.has(a.id) && !this.selectedProductIds.has(b.id))
                return -1;
            if(!this.selectedProductIds.has(a.id) && this.selectedProductIds.has(b.id))
                return 1;

            return 0;
        });

        this.numberOfCurrentProducts = this.currentProducts.length;
        this.numberOfVisibleProducts = this.numberOfProductsToLoad;
        
        if(this.numberOfCurrentProducts > this.numberOfProductsToLoad)
        {
            const tempArr = [];
        
            for(let i = 0; i < this.numberOfVisibleProducts; i++)
            {
                tempArr.push({
                    id: this.currentProducts[i].id,
                    name: this.currentProducts[i].name,
                    productId: this.currentProducts[i].productId,
                    quantity: this.currentProducts.quantity,
                    styleTotal: this.currentProducts[i].styleTotal,
                    total: this.currentProducts[i].total,
                    unitPrice: this.currentProducts[i].unitPrice
                });
            }
            this.visibleProducts = [...tempArr];
            this.template.querySelector('.product-datatable').enableInfiniteLoading = true;
        }
        else
        {
            this.visibleProducts = this.currentProducts;
            this.template.querySelector('.product-datatable').enableInfiniteLoading = false;
        }
    }

    processCellChange(event)
    {
        this.updateTotalAmount(event.detail.draftValues);
    }

    processSelection(event)
    {
        console.log(event.detail.selectedRows);
        this.selectedProducts = event.detail.selectedRows;
        this.selectedProductIds = new Set();

        const selectedProductsLength = this.selectedProducts.length;
        this.triggerProductsSelectedEvent(selectedProductsLength);

        for(let i = 0; i < selectedProductsLength; i++)
        {
            this.selectedProductIds.add(this.selectedProducts[i].id);
        }

        this.selectedRowIds = Array.from(this.selectedProductIds);
    }

    @api toggleShowSelected(event)
    {
        this.showSelected = !this.showSelected;
        this.triggerShowSelectedEvent();
    }

    @api getSelectedProducts()
    {
        if(this.validateFields())
        {
            const dealRegProducts = [];
            const tempLength = this.selectedProducts.length;
            for(let i = 0; i < tempLength; i++)
            {
                dealRegProducts.push({
                    CurrencyIsoCode: this.currencyIsoCode,
                    ListPrice__c: this.selectedProducts[i].unitPrice,
                    Name: this.selectedProducts[i].name,
                    PricebookId__c: this.selectedProducts[i].pricebookId,
                    PricebookEntryId__c: this.selectedProducts[i].id,
                    Product__c: this.selectedProducts[i].productId,
                    Quantity__c: this.selectedProducts[i].quantity,
                    UnitPrice__c: this.selectedProducts[i].unitPrice
                });
            }
            return dealRegProducts;
        }
        return [];
    }

    // Methods
    initColumns()
    {
        this.columns = [
            { label: 'Name', fieldName: 'name' },
            { label: 'Unit Price', fieldName: 'unitPrice', type: 'currency', fixedWidth: 150, typeAttributes: { currencyCode: this.currencyIsoCode}, cellAttributes:{class: {fieldName: 'styleTotal'}}}
        ];
    
        this.columnsSelectedTable = [
            { label: 'Name', fieldName: 'name' },
            { label: 'Unit Price', fieldName: 'unitPrice', type: 'currency', fixedWidth: 130, typeAttributes: { currencyCode: this.currencyIsoCode}},
            { label: 'Quantity', fieldName: 'quantity', type: 'number', editable: true, fixedWidth: 130 },
            { label: 'Total', fieldName: 'total', type: 'currency', fixedWidth: 130, typeAttributes: { currencyCode: this.currencyIsoCode}, cellAttributes:{class: {fieldName: 'styleTotal'}}}
        ];
    }

    initPricebookEntries()
    {
        getPricebookEntriesApex({
            priceBook: this.customLabels.PRICE_BOOK_NAME,
            currencyIsoCode: this.currencyIsoCode
        })
        .then(result => {    
            if(result)
            {
                const tempArr = [];
                this.numberOfCurrentProducts = result.length;
                for(let i = 0; i < this.numberOfCurrentProducts; i++)
                {
                    const tempRow = {
                        id: result[i].Id,
                        name: result[i].Name,
                        productId: result[i].Product2Id,
                        pricebookId: result[i].Pricebook2Id,
                        quantity: null,
                        styleTotal: 'slds-align_absolute-center',
                        total: 0,
                        unitPrice: result[i].UnitPrice
                    };

                    if ((this.dealType !== 'NFR' && tempRow.name.includes('NFR')) ||
                            (this.dealType === 'NFR' && !tempRow.name.includes('NFR'))
                    )
                    {
                        continue;
                    }
                    else
                    {
                        this.products.push(tempRow);
                        this.currentProducts.push(tempRow)
    
                        if(this.visibleProducts.length < this.numberOfVisibleProducts)
                            this.visibleProducts.push(tempRow);
                    }
                }

                this.visibleProducts = [...this.visibleProducts];

                this.isLoaded = true;
            }
            else
            {
                console.log('Results not true');
            }
        })
        .catch((error) => {
            console.log({error});
        })
    }

    updateTotalAmount(updatedProducts)
    {
        const tempLength = updatedProducts.length;
        for(let i = 0; i < tempLength; i++)
        {
            const productToUpdate = this.visibleProducts.find(product => product.id == updatedProducts[i].id);
            productToUpdate.quantity = updatedProducts[i].quantity;
            productToUpdate.total = (productToUpdate.unitPrice * updatedProducts[i].quantity);
        }
    }

    triggerProductsSelectedEvent(selectedProductsLength)
    {
        const productsSelectedEvent = new CustomEvent('getselectedproductslength', {
              detail: { selectedProductsLength }
        });

        this.dispatchEvent(productsSelectedEvent);
    }

    triggerShowSelectedEvent()
    {
        const showSelected = this.showSelected;
        const showSelectedEvent = new CustomEvent('getshowselected', {
              detail: { showSelected }
        });

        this.dispatchEvent(showSelectedEvent);
    }

    validateFields()
    {
        const tempErrors = { rows: {} };
        const tempLength = this.selectedProducts.length;
        for(let i = 0; i < tempLength; i++)
        {
            if(this.selectedProducts[i].quantity == null || this.selectedProducts[i].quantity == 0 || this.selectedProducts[i].quantity == '0')
            {
                tempErrors.rows[this.selectedProducts[i].id] = { title: 'Error found!', messages: [ 'Quantity can not be 0!'], fieldNames: ['quantity']};
            }
        }
        this.errors = tempErrors;
        
        if(Object.keys(this.errors.rows).length)
        {
            this.showToast('Quantity can not be 0!', 'Error found!', 'error');
            return false;
        }
        
        return true;
    }

    showToast(message, title, type)
    {
        const event = new ShowToastEvent({
            message: 'Quantity can not be 0!',
            title: 'Error found!',
            variant: 'error'
        });
        this.dispatchEvent(event);
    }
}