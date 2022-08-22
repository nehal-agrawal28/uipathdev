import { track, wire, LightningElement, api } from 'lwc';
import GetNotificationsList from '@salesforce/apex/GenericNotificationsController_PP.getNotifications';
import SaveNotification from '@salesforce/apex/GenericNotificationsController_PP.saveNotification';
import DeleteNotifications from '@salesforce/apex/GenericNotificationsController_PP.deleteNotifications';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {refreshApex} from '@salesforce/apex';
import EmailField from '@salesforce/schema/GenericNotification_PP__c.Email__c';
import TypeField from '@salesforce/schema/GenericNotification_PP__c.Type__c';
import labelNotificationDeleted from '@salesforce/label/c.NotificationDeleted_PP';
import labelNotificationUpdated from '@salesforce/label/c.NotificationUpdated_PP';
import labelSuccessTitle from '@salesforce/label/c.NotificationEventSuccessTitle_PP';
import labelErrorTitle from '@salesforce/label/c.NotificationEventErrorTitle_PP';
import RequireCommunityUserTitle from '@salesforce/label/c.NotificationRequiresCommunityUserTitle_PP';
import RequireCommunityUser from '@salesforce/label/c.NotificationRequiresCommunityUser_PP';

const actions = [
  { label: 'Edit', name: 'edit' },
  { label: 'Delete', name: 'delete' },
];

const columns = [
  { label: 'Email', fieldName: 'Email__c', type: 'email', sortable: true },
  { label: 'Type', fieldName: 'Type__c', type: 'text', sortable: true },
  {
    type: 'action',
    typeAttributes: { rowActions: actions },
  },
];


export default class DataTableComponent extends LightningElement {
  @track data;
  @track columns = columns;
  @track currentRecordId;
  @track showLoadingSpinner = false;
  @track showModal = false;
  @track isEditForm = false;
  @track isUserError = false;

  fields = [ EmailField, TypeField ];
  label = {
    RequireCommunityUserTitle,
    RequireCommunityUser
  };
  refreshTable;

  @wire(GetNotificationsList, {})
  notifications(result) {
    this.refreshTable = result;
    if (result.data) {
      this.data = result.data;
    } else if (result.error) {
      this.isUserError = true;
      //test
    }
  }

  // closing modal box
  closeModal() {
    this.showModal = false;
  }

  deleteNotification(currentRow) {
    this.currentRecordId = currentRow.Id;
    this.showLoadingSpinner = true;

    // calling apex class method to delete the selected contact
    DeleteNotifications({notificationIds: this.currentRecordId})
      .then(result => {
        this.showLoadingSpinner = false;

        // showing success message
        this.dispatchEvent(new ShowToastEvent({
          title: 'Success!!',
          message: currentRow.Email__c + ' '+ currentRow.Type__c + labelNotificationDeleted,
          variant: 'success'
        }),);

        // refreshing table data using refresh apex
        return refreshApex(this.refreshTable);

      })
      .catch(error => {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Error!!',
          message: error.message,
          variant: 'error'
        }),);
      });
  }

  editCurrentRecord(currentRow) {
    // open modal box
    this.showModal = true;
    this.isEditForm = true;

    // assign record id to the record edit form
    this.currentRecordId = currentRow.Id;
  }

  handleRowActions(event) {
    let actionName = event.detail.action.name;

    let row = event.detail.row;

    switch (actionName) {
      case 'edit':
        this.editCurrentRecord(row);
        break;
      case 'delete':
        this.deleteNotification(row);
        break;
    }
  }

  // handling record edit form submit
  handleSubmit(event) {
    // preventing default type submit of record edit form
    event.preventDefault();
    this.showLoadingSpinner = true;

    SaveNotification({notificationId: this.currentRecordId, email: event.detail.fields.Email__c, type: event.detail.fields.Type__c})
      .then(result => {
        this.showLoadingSpinner = false;

        // showing success message
        this.dispatchEvent(new ShowToastEvent({
          title: labelSuccessTitle,
          message: labelNotificationUpdated,
          variant: 'success'
        }),);

        this.handleSuccess();

      })
      .catch(error => {
        this.showLoadingSpinner = false;
        this.dispatchEvent(new ShowToastEvent({
          title: labelErrorTitle,
          message: error.message,
          variant: 'error'
        }),);
      });

    // closing modal
    this.showModal = false;
  }

  // refreshing the datatable after record edit form success
  handleSuccess() {
    return refreshApex(this.refreshTable);
  }

  newModal() {
    // open modal box
    this.showModal = true;
    this.isEditForm = false;
    this.currentRecordId = '';
  }
}