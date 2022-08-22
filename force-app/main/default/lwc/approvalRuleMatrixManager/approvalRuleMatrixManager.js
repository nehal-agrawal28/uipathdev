/* eslint-disable no-console */
import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import getInitialData_Apex from "@salesforce/apex/ApprovalRuleMatrixManagerController.getInitialData";
import getMatrixList_Apex from "@salesforce/apex/ApprovalRuleMatrixManagerController.getMatrixList";
import generateRule_Apex from "@salesforce/apex/ApprovalRuleMatrixManagerController.generateRule";
import saveMatrixRule_Apex from "@salesforce/apex/ApprovalRuleMatrixManagerController.saveMatrixRule";
import getSingleMatrixrRecord_Apex from "@salesforce/apex/ApprovalRuleMatrixManagerController.getSingleMatrixrRecord";
import toggleMatrixAndRuleStatus_Apex from "@salesforce/apex/ApprovalRuleMatrixManagerController.toggleMatrixAndRuleStatus";
import deleteMatrixRecords_Apex from "@salesforce/apex/ApprovalRuleMatrixManagerController.deleteMatrixRecords";

export default class ApprovalRuleMatrixManager extends NavigationMixin(LightningElement) {
  @track isSandbox = true;
  @track matrixList = [];
  @track approverList = [];
  @track approverListFilter = [];
  @track criteriaFieldList = [];
  @track ruleGenerationUIFieldList = [];
  @track showMatrixTable = false;
  @track showFilters = true;
  @track showSpinner = false;
  @track showNewMatrixSpinner = false;
  @track showNewMatrixModal = false;
  @track showDeleteMatrixWarning = false;
  @track filterCondition = "";
  @track disableActionButtons = false;
  @track showGenerateWarning = false;
  @track filterSection = {
    isOpen: false,
    sectionCSS: "slds-accordion__section slds-m-top_medium"
  };
  @track isFilterAND = false;

  /**
   * Connected callback lifecycle event when component is inserted into the DOM
   */
  connectedCallback() {
    this.fetchInitialData();
  }

  /**
   * Fetching data from server
   */
  fetchInitialData() {
    this.showSpinner = true;

    getInitialData_Apex()
      .then((wrapper) => {
        // Override using parameter
        // let adminParam = this.getUrlParamValue(window.location.href, "c__admin");
        // this.isSandbox = adminParam === "true" ? true : wrapper.isSandbox;

        this.isSandbox = wrapper.isSandbox;

        this.approverList = wrapper.approverList;

        this.approverListFilter.push({ label: "--None--", value: "" });
        for (let app of wrapper.approverList) {
          this.approverListFilter.push(app);
        }

        this.matrixList = wrapper.matrixList;
        this.processMatrixList();

        this.criteriaFieldList = wrapper.criteriaFieldList;
        this.ruleGenerationUIFieldList = wrapper.ruleGenerationUIFieldList;

        this.showMatrixTable = true;

        this.showSpinner = false;
      })
      .catch((error) => {
        this.showToast("Error", "Something went wrong while fetching data", "error");
        console.error("Error ApprovalRuleMatrixManagerController.getInitialData: " + JSON.stringify(error));
      });
  }
  fetchMatrixRecords(filterCondition, orderByCondition) {
    this.showSpinner = true;

    getMatrixList_Apex({
      filterCondition: filterCondition,
      orderByCondition: orderByCondition
    })
      .then((result) => {
        this.matrixList = result;
        this.processMatrixList();

        this.showMatrixTable = true;
        this.showFilters = true;
        this.showSpinner = false;
      })
      .catch((error) => {
        this.showToast("Error", "Something went wrong while fetching data", "error");
        console.error("Error ApprovalRuleMatrixManagerController.getMatrixList: " + JSON.stringify(error));
      });
  }
  fetchSingleMatrixRecord(matrixRecId, index) {
    getSingleMatrixrRecord_Apex({
      matrixRecId: matrixRecId
    })
      .then((result) => {
        result = this.processMatrixRecord(result);
        this.matrixList[index] = result;

        this.showSpinner = false;
      })
      .catch((error) => {
        this.showToast("Error", "Something went wrong while fetching data", "error");
        console.error("Error ApprovalRuleMatrixManagerController.getSingleMatrixrRecord_Apex: " + error);
        console.error(
          "Error ApprovalRuleMatrixManagerController.getSingleMatrixrRecord_Apex JSON: " + JSON.stringify(error)
        );
      });
  }
  toggleMatrixStatus(matrixRecId, index) {
    toggleMatrixAndRuleStatus_Apex({
      matrixRecId: matrixRecId
    })
      .then((result) => {
        result = this.processMatrixRecord(result);
        this.matrixList[index] = result;

        this.showSpinner = false;
      })
      .catch((error) => {
        this.showToast("Error", "Something went wrong while fetching data", "error");
        console.error("Error ApprovalRuleMatrixManagerController.toggleMatrixAndRuleStatus: " + error);
        console.error(
          "Error ApprovalRuleMatrixManagerController.toggleMatrixAndRuleStatus JSON: " + JSON.stringify(error)
        );
      });
  }
  processMatrixList() {
    for (let matrix of this.matrixList) {
      matrix = this.processMatrixRecord(matrix);
    }
  }
  processMatrixRecord(matrix) {
    matrix.isError = false;
    matrix.isPending = false;
    matrix.isSubmitted = false;
    matrix.isProcessed = false;
    matrix.disabled = matrix.Deployed_To_Production__c && matrix.ApprovalRule__c ? true : false;
    matrix.selected = false;
    matrix.isDrawerOpened = false;
    matrix.matrixURL = "/" + matrix.Id;
    matrix.ruleURL = matrix.ApprovalRule__c ? "/" + matrix.ApprovalRule__c : "";

    if (matrix.SyncStatus__c === "Error") {
      matrix.isError = true;
      //matrix.disabled = true;
    } else if (matrix.SyncStatus__c === "Submitted") {
      matrix.isSubmitted = true;
      //matrix.disabled = true;
    } else if (matrix.SyncStatus__c === "Processed") {
      matrix.isProcessed = true;
      //matrix.disabled = true;
    } else {
      matrix.isPending = true;
    }

    if (matrix.StaticApprover__c && matrix.StaticApprover__r) {
      matrix.combinedApprover = {
        label: matrix.StaticApprover__r.Name,
        value: matrix.StaticApprover__c,
        type: "Static Approver",
        isStaticApprover: true
      };
    } else if (matrix.DynamicApproverField__c && this.approverList) {
      let dynamicApprover = this.approverList.find((ele) => ele.value === matrix.DynamicApproverField__c);
      matrix.combinedApprover = {
        label: dynamicApprover.label,
        value: dynamicApprover.value,
        type: "Dynamic Approver",
        isStaticApprover: false
      };
    } else {
      matrix.combinedApprover = { label: "", value: "", type: "", isStaticApprover: false };
    }
    return matrix;
  }

  /**
   * Handle Generate Rule events
   */
  handleGenerateRule() {
    this.disableActionButtons = true;
    let selectedMatrixList = [];
    for (let matrix of this.matrixList) {
      if (matrix.selected) {
        selectedMatrixList.push(matrix);
      }
    }

    if (selectedMatrixList.length === 0) {
      this.showToast("Error", "Please select at lease one record to generate Rule", "error");
      this.disableActionButtons = false;
    } else {
      this.showGenerateWarning = true;

      //process matrix record status before server call
      for (let selectedMatrix of selectedMatrixList) {
        selectedMatrix.isProcessed = false;
        selectedMatrix.isError = false;
        selectedMatrix.isPending = false;
        selectedMatrix.isSubmitted = true;
        selectedMatrix.disabled = true;
        selectedMatrix.selected = false;
        selectedMatrix.isEditMode = false;
      }

      //call rule generation function
      this.generateRule(selectedMatrixList);
    }
  }
  generateRule(selectedMatrixList) {
    if (selectedMatrixList && selectedMatrixList.length > 0) {
      generateRule_Apex({
        matrixRecId: selectedMatrixList[0].Id
      })
        .then((result) => {
          //update matrix record
          for (let matrix of this.matrixList) {
            if (matrix.Id === selectedMatrixList[0].Id) {
              //update matrix record
              matrix.SyncStatus__c = result.SyncStatus__c;
              matrix.SyncMessage__c = result.SyncMessage__c;
              if (result.ApprovalRule__c) {
                matrix.ApprovalRule__c = result.ApprovalRule__c;
                matrix.ApprovalRule__r = { Id: result.ApprovalRule__c, Name: result.ApprovalRule__r.Name };
              }

              //process matrix record status after server call
              matrix.isProcessed = false;
              matrix.isError = false;
              matrix.isPending = false;
              matrix.isSubmitted = false;
              matrix.disabled = false;

              if (result.SyncStatus__c === "Error") {
                matrix.isError = true;
                console.error("Rule generation error MatrixId:" + result.Id + " Message:" + result.SyncMessage__c);
              } else if (result.SyncStatus__c === "Processed") {
                matrix.isProcessed = true;
              } else if (result.SyncStatus__c === "Submitted") {
                matrix.isSubmitted = true;
              }

              break;
            }
          }

          //remove top element
          selectedMatrixList.shift();
          //recursion
          this.generateRule(selectedMatrixList);
        })
        .catch((error) => {
          console.error("Error ApprovalRuleMatrixManagerController.generateRule: " + JSON.stringify(error));

          //remove top element
          selectedMatrixList.shift();
          //recursion
          this.generateRule(selectedMatrixList);
        });
    } else {
      this.showToast("Completed", "Rule generation process completed", "success");
      this.disableActionButtons = false;
      this.showGenerateWarning = false;
    }
  }

  /**
   * Handle new approval matrix events
   */
  handleNewApprovalMatrix() {
    this.showNewMatrixModal = true;
    this.showNewMatrixSpinner = true;
  }
  handleNewMatrixModalClose() {
    this.showNewMatrixModal = false;
  }
  handleNewMatrixFormLoad() {
    this.showNewMatrixSpinner = false;
  }
  handleNewMatrixFormSubmit(event) {
    event.preventDefault();
    let fields = event.detail.fields;
    let approverField = this.template.querySelector(".new-approver-field");
    let approverValue = approverField.value;

    if (approverValue && approverValue !== "") {
      let approverObj = {};
      for (let approver of this.approverList) {
        if (approver.value === approverValue) {
          approverObj = approver;
          break;
        }
      }
      if (approverObj.type === "Static Approver") {
        fields.StaticApprover__c = approverObj.value;
      } else {
        fields.DynamicApproverField__c = approverObj.value;
      }

      this.showNewMatrixSpinner = true;
      this.template.querySelector(".new-approval-matrix-form").submit(fields);
    } else {
      approverField.showHelpMessageIfInvalid();
    }
  }
  handleNewMatrixFormError() {
    this.showNewMatrixSpinner = false;
  }
  handleNewMatrixFormSuccess() {
    this.showNewMatrixSpinner = false;
    this.showNewMatrixModal = false;

    this.showFilters = false;
    this.showMatrixTable = false;
    this.fetchMatrixRecords("", "");
  }

  /**
   * Handle delete related events
   */
  handleDeleteMatrix() {
    let selectedMatrixIdList = [];
    for (let matrix of this.matrixList) {
      if (matrix.selected) {
        selectedMatrixIdList.push(matrix);
      }
    }

    if (selectedMatrixIdList.length === 0) {
      this.showToast("Error", "Please select at lease one rule to delete", "error");
    } else {
      this.showDeleteMatrixWarning = true;
    }
  }
  handleDeleteMatrixWarningClose() {
    this.showDeleteMatrixWarning = false;
  }
  handleDeleteMatrixConfirm() {
    this.disableActionButtons = true;
    this.showDeleteMatrixWarning = false;
    this.showSpinner = true;
    let selectedMatrixIdList = [];
    for (let matrix of this.matrixList) {
      if (matrix.selected) {
        selectedMatrixIdList.push(matrix.Id);
      }
    }

    deleteMatrixRecords_Apex({
      matrixIdList: selectedMatrixIdList
    })
      .then(() => {
        this.disableActionButtons = false;
        this.showToast("Success", "Rule(s) deleted successfully", "success");

        this.fetchMatrixRecords("", "");
      })
      .catch((error) => {
        this.showToast("Error", "Something went wrong while deleting data", "error");
        console.error("Error ApprovalRuleMatrixManagerController.deleteMatrixRecords: " + error);
        console.error("Error ApprovalRuleMatrixManagerController.deleteMatrixRecords JSON: " + JSON.stringify(error));
      });
  }
  handleDeleteMatrixWithCPQ() {
    this.showToast("TODO", "Pending...", "info");
  }

  /**
   * Handle inline edit approval matrix events
   */
  handleInlineEdit(event) {
    let index = event.target.dataset.index;
    this.matrixList[index].isEditMode = true;
  }
  handleInlineEditChange(event) {
    let index = event.target.dataset.index;
    let property = event.target.dataset.property;
    let type = event.target.type;

    if (property === "combinedApprover") {
      let approverValue = event.target.value;
      let approverObj = {};
      for (let approver of this.approverList) {
        if (approver.value === approverValue) {
          approverObj = approver;
          break;
        }
      }
      if (approverObj.type === "Static Approver") {
        this.matrixList[index].combinedApprover = approverObj;
        this.matrixList[index].StaticApprover__c = approverObj.value;
        this.matrixList[index].DynamicApproverField__c = "";
      } else {
        this.matrixList[index].combinedApprover = approverObj;
        this.matrixList[index].StaticApprover__c = "";
        this.matrixList[index].StaticApprover__r = null;
        this.matrixList[index].DynamicApproverField__c = approverObj.value;
      }
    } else {
      if (type === "checkbox") {
        this.matrixList[index][property] = event.target.checked;
      } else {
        this.matrixList[index][property] = event.target.value;
      }
    }
  }
  handleInlineSave(event) {
    let index = event.target.dataset.index;

    let matrixRec = this.matrixList[index];
    let objToSave = {
      Id: matrixRec.Id,
      Name: matrixRec.Name,
      Active__c: matrixRec.Active__c,
      StaticApprover__c: matrixRec.StaticApprover__c,
      DynamicApproverField__c: matrixRec.DynamicApproverField__c
    };
    this.showSpinner = true;

    saveMatrixRule_Apex({
      matrixRecString: JSON.stringify(objToSave)
    })
      .then((result) => {
        result = this.processMatrixRecord(result);
        this.matrixList[index] = result;

        this.showSpinner = false;
      })
      .catch((error) => {
        if (error.body) {
          this.showToast("Error", error.body.message, "error");
          this.showSpinner = false;
        } else {
          this.showToast("Error", "Something went wrong while saving data", "error");
        }
        console.error("Error ApprovalRuleMatrixManagerController.saveMatrixRule: " + error);
        console.error("Error ApprovalRuleMatrixManagerController.saveMatrixRule JSON: " + JSON.stringify(error));
      });
  }
  handleInlineCancel(event) {
    let index = event.target.dataset.index;
    let matrixRecId = this.matrixList[index].Id;
    this.showSpinner = true;

    this.fetchSingleMatrixRecord(matrixRecId, index);
  }
  handleInlineStatusToggle(event) {
    let index = event.target.dataset.index;
    let matrixRecId = this.matrixList[index].Id;
    this.showSpinner = true;

    this.toggleMatrixStatus(matrixRecId, index);
  }

  /**
   * Handle drawer related events
   */
  handleDrawerOpen(event) {
    let index = event.target.dataset.index;
    this.matrixList[index].isDrawerOpened = true;
    this.showSpinner = true;
  }
  handleDrawerClose(event) {
    let index = event.target.dataset.index;
    this.matrixList[index].isDrawerOpened = false;
  }
  handleDrawerFormLoad() {
    this.showSpinner = false;
  }
  handleDrawerFormSubmit() {
    this.showSpinner = true;
  }
  handleDrawerFormError() {
    this.showSpinner = false;
    this.showToast("Error", "Error occured while saving record", "error");
  }
  handleDrawerFormSuccess(event) {
    let index = event.target.dataset.index;
    let matrixRecId = this.matrixList[index].Id;

    this.fetchSingleMatrixRecord(matrixRecId, index);
    this.showToast("Success", "Record saved successfully", "success");
  }

  /**
   * Handle table events
   */
  handleColumnSort(event) {
    let columnKey = event.currentTarget.dataset.columnKey;
    let sortDir = event.currentTarget.classList.contains("sort_asc_visible") ? "sort_desc_visible" : "sort_asc_visible";

    this.removeAllCarets();
    let columnList = columnKey.split(".");

    this.matrixList.sort((a, b) => {
      let i = 0;
      let aVal =
        a[columnList[i]] !== null && a[columnList[i]] !== undefined && a[columnList[i]] !== ""
          ? typeof a[columnList[i]] === "object"
            ? a[columnList[i]]
            : a[columnList[i]] + ""
          : "";
      let bVal =
        b[columnList[i]] !== null && b[columnList[i]] !== undefined && b[columnList[i]] !== ""
          ? typeof b[columnList[i]] === "object"
            ? b[columnList[i]]
            : b[columnList[i]] + ""
          : "";

      for (i = 1; i <= columnList.length - 1; i++) {
        aVal =
          aVal !== null && aVal !== undefined && aVal !== ""
            ? typeof aVal === "object"
              ? aVal[columnList[i]]
              : ""
            : "";
        bVal =
          bVal !== null && bVal !== undefined && bVal !== ""
            ? typeof bVal === "object"
              ? bVal[columnList[i]]
              : ""
            : "";
      }

      if (sortDir === "sort_asc_visible") {
        event.currentTarget.classList = "sort sort_asc_visible";
        return aVal.localeCompare(bVal, "en", { sensitivity: "case" });
      }
      event.currentTarget.classList = "sort sort_desc_visible";
      return bVal.localeCompare(aVal, "en", { sensitivity: "case" });
    });
  }
  removeAllCarets() {
    for (let th of this.template.querySelectorAll("th.sort")) {
      th.classList = "sort";
    }
  }
  handleSelection(event) {
    let index = event.target.value;
    this.matrixList[index].selected = event.target.checked;
  }
  handleAllSelection(event) {
    let allSelected = event.target.checked;
    for (let matrix of this.matrixList) {
      if (allSelected && matrix.disabled === false) {
        matrix.selected = true;
      } else {
        matrix.selected = false;
      }
    }
  }

  /**
   * Handle filters related events
   */
  handleFilterToggle(event) {
    this.isFilterAND = event.target.checked;
  }
  handleFilterClick() {
    let fields = this.template.querySelectorAll(".filter-field");
    let filterCondition = "";
    let filterCriteriaCondition = "";
    let filterCriteriaOperator = this.isFilterAND ? "AND" : "OR";

    //process fields to build filter condition
    for (let fl of fields) {
      let criteriaField = fl.dataset.criteriaField;
      let fieldType = fl.dataset.fieldType;
      let fieldName = fl.fieldName;
      let value = fl.value;

      if (criteriaField === "true" && this.filterSection.isOpen) {
        //applying criteria filters
        if (value !== undefined && value !== "" && value !== null && value !== false) {
          if (
            fieldType === "BOOLEAN" ||
            fieldType === "CURRENCY" ||
            fieldType === "PERCENT" ||
            fieldType === "DOUBLE"
          ) {
            if (filterCriteriaCondition !== "") {
              filterCriteriaCondition += " " + filterCriteriaOperator + " " + fieldName + "=" + value;
            } else {
              filterCriteriaCondition += fieldName + "=" + value;
            }
          } else {
            if (filterCriteriaCondition !== "") {
              filterCriteriaCondition += " " + filterCriteriaOperator + " " + fieldName + "='" + value + "'";
            } else {
              filterCriteriaCondition += fieldName + "='" + value + "'";
            }
          }
        }
      } else if (criteriaField !== "true") {
        //applying top filters
        if (value !== undefined && value !== "" && value !== null) {
          if (
            fieldType === "BOOLEAN" ||
            fieldType === "CURRENCY" ||
            fieldType === "PERCENT" ||
            fieldType === "DOUBLE"
          ) {
            filterCondition += " AND " + fieldName + "=" + value;
          } else {
            if (fieldName === "Name") {
              filterCondition += " AND " + fieldName + " LIKE '%" + value + "%'";
            } else {
              filterCondition += " AND " + fieldName + "='" + value + "'";
            }
          }
        }
      }
    }

    if (filterCriteriaCondition && filterCriteriaCondition !== "") {
      filterCondition = filterCondition + " AND (" + filterCriteriaCondition + ")";
    }

    //process combined approver filter
    let combinedApproverVal = this.template.querySelector(".filter-approver").value;
    if (combinedApproverVal && combinedApproverVal !== "") {
      let approverObj = {};
      for (let approver of this.approverList) {
        if (approver.value === combinedApproverVal) {
          approverObj = approver;
          break;
        }
      }
      if (approverObj.type === "Static Approver") {
        filterCondition += " AND StaticApprover__c='" + approverObj.value + "'";
      } else {
        filterCondition += " AND DynamicApproverField__c='" + approverObj.value + "'";
      }
    }

    console.log("filterCondition:: " + filterCondition);
    this.filterCondition = filterCondition;
    this.fetchMatrixRecords(filterCondition, "");
  }
  handleClearFilter() {
    this.showFilters = false;
    this.filterCondition = "";
    this.fetchMatrixRecords("", "");
  }
  handleFilterSectionOpen() {
    this.filterSection = {
      isOpen: true,
      sectionCSS: "slds-accordion__section slds-m-top_medium slds-is-open"
    };
  }
  handleFilterSectionClose() {
    this.filterSection = {
      isOpen: false,
      sectionCSS: "slds-accordion__section slds-m-top_medium"
    };
  }

  /**
   * Other helper funtions
   */
  handleNavigateToRecord(event) {
    let recId = event.currentTarget.dataset.recId;

    if (event.ctrlKey) {
      this[NavigationMixin.GenerateUrl]({
        type: "standard__recordPage",
        attributes: {
          actionName: "view",
          recordId: recId
        }
      }).then((url) => {
        window.open(url, "_blank");
      });
    } else {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          actionName: "view",
          recordId: recId
        }
      });
    }
  }
  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(evt);
  }
  getUrlParamValue(url, key) {
    return new URL(url).searchParams.get(key);
  }
}