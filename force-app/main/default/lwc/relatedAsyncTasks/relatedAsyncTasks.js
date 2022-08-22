import { LightningElement, api, track } from "lwc";
import getAsyncTasksData_Apex from "@salesforce/apex/RelatedAsyncTasksController.getAsyncTasksData";
import retryAsyncTask_Apex from "@salesforce/apex/RelatedAsyncTasksController.retryAsyncTask";

export default class RelatedAsyncTasks extends LightningElement {
  @api recordId;
  @track isVisible;
  @track showSpinner;
  @track asyncTasks;

  connectedCallback() {
    this.isVisible = false;
    this.fetchInitialData();
  }

  fetchInitialData() {
    getAsyncTasksData_Apex({
      recordId: this.recordId
    })
      .then((results) => {
        this.asyncTasks = results.asyncTasks;
        if (this.asyncTasks && this.asyncTasks.length > 0) {
          for (let task of this.asyncTasks) {
            task.url = "/" + task.Id;
            if (task.Status__c === "Error") {
              task.isError = true;
              task.allowRetry = true;
            } else if (task.Status__c === "Completed") {
              task.isSuccess = true;
            } else {
              task.isOther = true;
            }
          }
          this.isVisible = true;
        }
        this.showSpinner = false;
      })
      .catch((error) => {
        console.error("RelatedAsyncTasksController.getAsyncTasksData Error: " + JSON.stringify(error));
      });
  }

  retryTask(event) {
    let index = event.target.dataset.index;
    let asyncTaskId = this.asyncTasks[index].Id;
    this.showSpinner = true;
    retryAsyncTask_Apex({
      asyncTaskId: asyncTaskId
    })
      .then(() => {
        this.fetchInitialData();
      })
      .catch((error) => {
        console.error("RelatedAsyncTasksController.retryAsyncTask Error: " + JSON.stringify(error));
      });
  }
}