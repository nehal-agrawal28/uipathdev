import { LightningElement, wire, api } from "lwc";
import { getPicklistValues } from "lightning/uiObjectInfoApi";

import COUNTRY_FIELD from "@salesforce/schema/Case.Country__c";
import ISD_CODE_FIELD from "@salesforce/schema/Case.Country_Code__c";
import DEPLOYMENT_FIELD from "@salesforce/schema/Case.DesiredDeployment__c";
//JS Utils
import { getConstants } from "c/dealHubConstants";
//Apex Classes
import validateLicenseCode from "@salesforce/apex/LicenseValidator_SV.validateLicenseCode";
import submitCase from "@salesforce/apex/DealHubCaseCreator_SV.submitCase";
//Custom Labels
import PriorityDescription from "@salesforce/label/c.PriorityDescription";
import LicenseCodeDesc from "@salesforce/label/c.LicenseCodeDesc";
import ValidateLicenseCode from "@salesforce/label/c.SupportFormValidateLicenseCode";
import InvalidLicenseCode from "@salesforce/label/c.Invalid_License_code";
import SuccessMessage from "@salesforce/label/c.Case_Success_Message";

const CONSTANTS = getConstants();

export default class DealHubSupportForm extends LightningElement {
  label = {
    PriorityDescription,
    LicenseCodeDesc,
    ValidateLicenseCode,
    InvalidLicenseCode,
    SuccessMessage
  };

  name;
  subject;
  description;
  email;
  country;
  phone;
  priority;
  deployment;
  licenseCode;
  orgName;
  currentDeployment;
  accountId;

  gridData;

  disableValidate;
  disableSubmit;
  loading;

  messageTitle;
  messageDesc;
  displayMessage;

  error;
  errors;

  draftValues = [];

  countries;
  countryCodes;
  countryMap;

  recordTypeId = CONSTANTS.DEFAULT_RECORD_TYPE_ID;

  @wire(getPicklistValues, { recordTypeId: "$recordTypeId", fieldApiName: COUNTRY_FIELD })
  fetchCountries({ error, data }) {
    if (data) {
      this.countries = this.buildOptions(data.values);
      this.error = undefined;
    } else {
      this.error = error;
      this.countries = undefined;
    }
  }

  @wire(getPicklistValues, { recordTypeId: "$recordTypeId", fieldApiName: DEPLOYMENT_FIELD })
  fetchDeployments({ error, data }) {
    if (data) {
      this.deployments = this.buildOptions(data.values);
      this.error = undefined;
    } else {
      this.error = error;
      this.deployments = undefined;
    }
  }

  @wire(getPicklistValues, { recordTypeId: "$recordTypeId", fieldApiName: ISD_CODE_FIELD })
  fetchCountryCodes({ error, data }) {
    if (data) {
      this.countryMap = data.controllerValues;
      this.countryCodes = this.buildOptions(data.values);
      this.error = undefined;
    } else {
      this.error = error;
      this.countryCodes = undefined;
    }
  }

  handleChange(event) {
    const field = event.target.name;
    if (field === "name") {
      this.name = event.target.value;
    } else if (field === "email") {
      this.email = event.target.value;
    } else if (field === "country") {
      this.country = event.target.value;
    } else if (field === "phone") {
      this.phone = event.target.value;
    } else if (field === "priority") {
      this.priority = event.target.value;
    } else if (field === "subject") {
      this.subject = event.target.value;
    } else if (field === "description") {
      this.description = event.target.value;
    } else if (field === "deployment") {
      this.deployment = event.target.value;
    } else if (field === "licenseCode") {
      this.licenseCode = event.target.value;
    } else if (field === "currentDeployment") {
      this.currentDeployment = event.target.value;
    }

    if (!event.target.validity.valid) {
      this.disableSubmit = true;
      return;
    }
  }

  @api
  get disableValidate() {
    return this.isValueEmpty(this.licenseCode);
  }

  @api
  get disableSubmit() {
    let isFormEmpty =
      this.isValueEmpty(this.name) ||
      this.isValueEmpty(this.email) ||
      this.isValueEmpty(this.country) ||
      this.isValueEmpty(this.phone) ||
      this.isValueEmpty(this.priority) ||
      this.isValueEmpty(this.deployment) ||
      this.isValueEmpty(this.licenseCode) ||
      this.isValueEmpty(this.currentDeployment) ||
      this.isValueEmpty(this.requestedQuantity);
    return isFormEmpty;
  }

  isValueEmpty(value) {
    return value == undefined || value == "" || value.trim() == "";
  }

  buildOptions(dataValues) {
    let picklistOptions = [];
    dataValues.forEach(function (elem) {
      picklistOptions.push({ label: elem.label, value: elem.value });
    });

    return picklistOptions;
  }

  get priorities() {
    return [
      { label: "Low", value: "Low" },
      { label: "Medium", value: "Medium" },
      { label: "High", value: "High" },
      { label: "Urgent", value: "Urgent" }
    ];
  }

  handleValidation(event) {
    this.loading = true;
    let licenseCodeField = this.template.querySelector("[data-id='licenseCode']");
    validateLicenseCode({ licenseCode: this.licenseCode })
      .then((result) => {
        this.gridData = result.gridData;
        this.orgName = result.name;
        this.accountId = result.accountId;
        this.error = undefined;
        this.loading = false;
        licenseCodeField.setCustomValidity("");
        licenseCodeField.reportValidity();
      })
      .catch((error) => {
        this.error = error;
        this.gridData = undefined;
        this.orgName = undefined;
        this.loading = false;
        licenseCodeField.setCustomValidity(this.label.InvalidLicenseCode);
        licenseCodeField.reportValidity();
      });
  }

  get requestedQtyByLicense() {
    return this.draftValues.reduce((obj, item) => ((obj[item.licenseCode] = item.requestedQuantity), obj), {});
  }

  get phoneCodeByCountry() {
    return this.countryCodes.reduce((obj, item) => ((obj[item.label] = item.value), obj), {});
  }

  handleSave(event) {
    try {
      this.draftValues = event.detail.draftValues;
      this.gridData.forEach((eachRow) => {
        let code = eachRow.licenseCode;
        let requestedQty = this.requestedQtyByLicense[code];

        if (requestedQty) {
          eachRow.requestedQuantity = requestedQty;
        }
      });
      this.draftValues = [];
    } catch (error) {
      console.error(error);
    }
  }

  get requestedQuantity() {
    let qty = "";
    try {
      this.gridData.forEach((eachRow) => {
        let code = eachRow.name;
        let requestedQty = eachRow.requestedQuantity;
        if (requestedQty && requestedQty > 0) {
          qty += code + ":" + requestedQty + ";";
        }
      });
    } catch (e) {
      console.error("ERROR " + e);
    }
    return qty;
  }

  submitCase(event) {
    this.disableSubmit = true;
    this.loading = true;
    this.displayMessage = false;
    this.messageTitle = undefined;
    this.messageDesc = undefined;

    let caseData = { sobjectType: "Case" };
    caseData.SuppliedName = this.name;
    caseData.SuppliedEmail = this.email;
    caseData.End_Customer_s_Name__c = this.orgName;
    caseData.AccountId = this.accountId;
    caseData.SuppliedPhone = this.phone;
    caseData.Priority = this.priority;
    caseData.Subject = this.subject;
    caseData.Description = this.description;
    caseData.Country__c = this.country;
    caseData.License_Code__c = this.licenseCode;
    caseData.License_Code_2__c = this.licenseCode;
    caseData.RecordTypeId = this.recordTypeId;
    caseData.Requested_Quantity__c = this.requestedQuantity;
    caseData.CurrentDeployment__c = this.currentDeployment;
    caseData.DesiredDeployment__c = this.deployment;
    caseData.Status = CONSTANTS.DEFAULT_STATUS;
    caseData.Request_Type__c = CONSTANTS.DEFAULT_REQUEST_TYPE;
    caseData.Origin = CONSTANTS.DEFAULT_ORIGIN;

    submitCase({ caseData: caseData })
      .then((result) => {
        this.displayMessage = true;
        this.messageTitle = "Success";
        this.messageDesc = this.label.SuccessMessage;
        this.resetForm();
        this.error = undefined;
        this.loading = false;
      })
      .catch((error) => {
        console.error(error);
        this.displayMessage = true;
        this.disableSubmit = false;
        this.messageTitle = "Error";
        this.messageDesc = "Unable to submit the case.";
        this.error = error;
        this.loading = false;
      });
  }

  resetForm() {
    this.disableSubmit = true;
    this.name = undefined;
    this.email = undefined;
    this.country = undefined;
    this.phone = undefined;
    this.priority = undefined;
    this.subject = undefined;
    this.description = undefined;
    this.deployment = undefined;
    this.licenseCode = undefined;
    this.currentDeployment = undefined;
    this.gridData = undefined;
    this.orgName = undefined;
    this.accountId = undefined;
  }

  gridColumns = [
    {
      type: "text",
      fieldName: "name",
      label: "Name",
      wrapText: true
    },
    {
      type: "number",
      fieldName: "requestedQuantity",
      label: "Quantity to be Moved",
      editable: true,
      initialWidth: 200,
      cellAttributes: { alignment: "left" },
      typeAttributes: { step: "1" }
    }
  ];
}