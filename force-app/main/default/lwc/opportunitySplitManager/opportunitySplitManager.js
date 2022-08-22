import { LightningElement, api, track } from 'lwc';
import getOppSplits from '@salesforce/apex/OpportunitySplitManagerController_ET.getOppSplits';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import deleteOppSplits from '@salesforce/apex/OpportunitySplitManagerController_ET.deleteOppSplits';

const columns = [
    {
        label: 'Opportunity Split',
        fieldName: 'nameUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        },
        sortable: false
    }, {
        label: 'Team Member',
        fieldName: 'userNameUrl',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'userName' },
            target: '_blank'
        },
        sortable: false
    }, {
        label: 'Split %',
        fieldName: 'Percentage__c',
        type: 'Decimal',
        editable: true,
    }, {
        label: 'Role',
        fieldName: 'TeamMemberRole__c',
        type: 'text',
        editable: false,
    }, {
        label: 'Include In Compensation',
        fieldName: 'Included_in_Compensation__c',
        type: 'text',
        editable: false
    }
];

export default class OpportunitySplitManager extends NavigationMixin(LightningElement) {

    @track opportunitySplits = [];
    columns = columns;
    @api recordId;
    selectedRecords = [];
    saveDraftValues = [];
    canSplitCreate = false;
    canSplitDelete = false;
    recordsCount = 0;
    openModal = false;
    isLoading = false;

    @api
    get noRecords() {
        return this.opportunitySplits.length == 0 ? true : false;
    }

    @api
    get styleLength() {
        return this.opportunitySplits.length > 9 ? 'height:300px;' : 'height:100%;';
    }
    @api
    get disableDelete() {
        this.selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        return this.selectedRecords.length > 0 ? false : true;
    }

    showModal() {
        this.openModal = true;
    }
    closeModal() {
        this.openModal = false;
    }

    connectedCallback() {
        this.fetchOppSplits();
    }

    handleSave(event) {
        this.isLoading = true;
        this.saveDraftValues = event.detail.draftValues;
        const recordInputs = this.saveDraftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });

        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(res => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Opportunity Split(s) Updated Successfully!!',
                    variant: 'success'
                })
            );
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Error while updating Opportunity Split(s)!!. Please contact System Admin',
                    variant: 'error'
                })
            );
        }).finally(() => {
            this.saveDraftValues = [];
            this.fetchOppSplits();
        });
    }

    handleDelete() {
        this.openModal = false;
        this.recordsCount = this.selectedRecords.length;
        let oppSplitIds = new Set();
        for (let row of this.selectedRecords) {
            oppSplitIds.add(row.Id);
        }
        this.deleteOppSplits(Array.from(oppSplitIds));
    }

    deleteOppSplits(oppSplitIds) {
        this.isLoading = true;
        deleteOppSplits({oppSplitIds: oppSplitIds})
            .then(result => {
                this.fetchOppSplits();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!!',
                        message: this.recordsCount + ' Opportunity Spilt(s) deleted.',
                        variant: 'success'
                    }),
                );
                this.template.querySelector('lightning-datatable').selectedRows = [];
                this.recordsCount = 0;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while deleting Opportunity Split(s)',
                        message: error.message,
                        variant: 'error'
                    }),
                );
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    fetchOppSplits() {
        this.isLoading = true;
        getOppSplits({ oppId: this.recordId })
            .then(result => {
                this.opportunitySplits = undefined;
                this.canSplitCreate = result.canSplitCreate;
                this.canSplitDelete = result.canSplitDelete;
                let nameUrl;
                let userNameUrl;
                let userName;
                this.opportunitySplits = result.listOfOppSplit.map(row => {
                    userName = row.User__c != null ? row.User__r.Name : '';
                    nameUrl = `/${row.Id}`;
                    userNameUrl = row.User__c != null ? `/${row.User__r.Id}` : '';
                    return {...row , userNameUrl, nameUrl, userName}
                })
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.opportunitySplits = undefined;
            })
            .finally(() => {
                this.isLoading = false;
            })
    }

    handleRefresh(){
        this.fetchOppSplits();
    }

    navigateToNewRecord() {
        const defaultValues = encodeDefaultFieldValues({
            Opportunity__c : this.recordId
        });
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity_Split__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues
            }
        });
    }
}