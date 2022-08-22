import { LightningElement, api } from 'lwc';
import { FlowNavigationBackEvent, FlowNavigationNextEvent } from 'lightning/flowSupport';
import createPartner from '@salesforce/apex/SelfRegController_PP.createPartner';
import PREVIOUS from '@salesforce/label/c.Previous';
import SUBMIT_REGISTRATION from '@salesforce/label/c.Submit_Registration';

const MUST_HAVE_NUMBER_REGEX = /(?=.*[0-9])/;
const MUST_HAVE_UPPER_CASE_REGEX = /(?=.*[A-Z])/;
const MUST_HAVE_LOWER_CASE_REGEX = /(?=.*[a-z])/;
const MUST_HAVE_SPECIAL_CHARACTER_REGEX = /(?=.*[\-_!@#$%])/;

export default class SelfRegFlowScreenSetPassword extends LightningElement {
  labels = {
    PREVIOUS,
    SUBMIT_REGISTRATION,
  };

  @api
  firstName = '';

  @api
  lastName = '';

  @api
  workEmail = '';

  @api
  contactId = '';

  @api
  country = '';

  @api
  selectedPartnerAccountId = '';

  @api
  isPartnerUserCreated = false;

  @api
  isCountryJapan = false;

  @api
  isRegistersDeal = false;

  isSubmitButtonDisabled = false;

  isLoading = false;

  hasErrors = false;

  passwordValue = '';

  passwordConfirmValue = '';

  validatePassword() {
    this.hasErrors = false;

    const passwordField = this.template.querySelector('.password-field');
    const passwordConfirmField = this.template.querySelector('.password-confirm-field');

    passwordField.setCustomValidity('');
    passwordConfirmField.setCustomValidity('');

    passwordField.reportValidity();
    passwordConfirmField.reportValidity();

    if (!passwordField.value || !(passwordField.value.length >= 8 && passwordField.value.length <= 16)) {
      passwordField.setCustomValidity('Must contain at least 8 characters, up to 16 characters');
    } else if (!MUST_HAVE_UPPER_CASE_REGEX.test(passwordField.value)) {
      passwordField.setCustomValidity('Must contain at least one upper case alpha character');
    } else if (!MUST_HAVE_LOWER_CASE_REGEX.test(passwordField.value)) {
      passwordField.setCustomValidity('Must contain at least one lower case alpha character');
    } else if (!MUST_HAVE_NUMBER_REGEX.test(passwordField.value)) {
      passwordField.setCustomValidity('Must contain at least one number');
    } else if (!MUST_HAVE_SPECIAL_CHARACTER_REGEX.test(passwordField.value)) {
      passwordField.setCustomValidity('Must contain at least one special character');
    } else if (passwordField.value.includes(this.workEmail) || passwordField.value.includes(this.lastName)) {
      passwordField.setCustomValidity('Password can not contain your email address or last name');
    } else if (passwordField.value !== passwordConfirmField.value) {
      passwordConfirmField.setCustomValidity('Password does not match');
    }

    const isValidPassword = passwordField.reportValidity();
    const isValidPasswordConfirm = passwordConfirmField.reportValidity();

    if (!isValidPassword || !isValidPasswordConfirm) {
      this.hasErrors = true;
    }
  }

  handleChangePassword(event) {
    this.passwordValue = event.currentTarget.value;
    this.validatePassword();
  }

  handleChangePasswordConfirm(event) {
    this.passwordConfirmValue = event.currentTarget.value;
    this.validatePassword();
  }

  handleClickPrevious() {
    this.dispatchEvent(new FlowNavigationBackEvent());
  }

  isContentUser(){
    if(!this.isRegistersDeal || this.isCountryJapan){
      return true;
    } else {
      return false;
    }
  }

  handleClickSubmit() {
    this.isSubmitButtonDisabled = true;
    this.isLoading = true;

    this.validatePassword();

    if (this.hasErrors) {
      this.isSubmitButtonDisabled = false;
      this.isLoading = false;
      return;
    }

    const payload = {
      contactId: this.contactId,
      accountId: this.selectedPartnerAccountId,
      firstname: this.firstName,
      country: this.country,
      isContentUser: this.isContentUser(),
      lastname: this.lastName,
      workEmail: this.workEmail,
      password: this.passwordValue,
    };

    createPartner(payload)
      .then((response) => {
        if (response) {
          this.isPartnerUserCreated = true;
        }

        this.dispatchEvent(new FlowNavigationNextEvent());
      })
      .catch(() => this.dispatchEvent(new FlowNavigationNextEvent()));
  }
}