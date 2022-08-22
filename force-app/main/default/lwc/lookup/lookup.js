import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const SEARCH_DELAY = 300; // Wait 300 ms after user stops typing then, peform search

const KEY_ARROW_UP = 38;
const KEY_ARROW_DOWN = 40;
const KEY_ENTER = 13;

const VARIANT_LABEL_STACKED = 'label-stacked';
const VARIANT_LABEL_INLINE = 'label-inline';
const VARIANT_LABEL_HIDDEN = 'label-hidden';

const REGEX_TRAP = /[+\\?^${}()|[\]\\]/g;

// @see https://github.com/pozil/sfdc-ui-lookup-lwc
export default class Lookup extends NavigationMixin(LightningElement) {
  // Public properties
  @api variant = VARIANT_LABEL_STACKED;

  @api label = '';

  @api required = false;

  @api disabled = false;

  @api placeholder = '';

  @api isMultiEntry = false;

  @api errors = [];

  @api scrollAfterNItems = null;

  @api newRecordOptions = [];

  @api minSearchTermLength = 2;

  // Template properties
  searchResultsLocalState = [];

  loading = false;

  // Private properties
  privateHasFocus = false;

  privateIsDirty = false;

  privateSearchTerm = '';

  privateCleanSearchTerm;

  privateCancelBlur = false;

  privateSearchThrottlingTimeout;

  privateSearchResults = [];

  privateDefaultSearchResults = [];

  privateCurSelection = [];

  privateFocusedResultIndex = null;

  // PUBLIC FUNCTIONS AND GETTERS/SETTERS
  @api
  set selection(initialSelection) {
    this.privateCurSelection = Array.isArray(initialSelection)
      ? initialSelection
      : [initialSelection];
    this.processSelectionUpdate(false);
    this.privateHasFocus = false;
  }

  get selection() {
    return this.privateCurSelection;
  }

  @api
  setSearchResults(results) {
    // Reset the spinner
    this.loading = false;
    // Clone results before modifying them to avoid Locker restriction
    const resultsLocal = JSON.parse(JSON.stringify(results));
    // Format results
    const cleanSearchTerm = this.privateSearchTerm.replace(REGEX_TRAP, '');
    const regex = new RegExp(`(${cleanSearchTerm})`, 'gi');
    this.privateSearchResults = resultsLocal.map((item) => {
      const result = { ...item };
      // Format title and subtitle
      if (this.privateSearchTerm.length > 0) {
        result.titleFormatted = result.title
          ? result.title.replace(regex, '<strong>$1</strong>')
          : result.title;
        /* commented out since we are only using title in search criteria
        result.subtitleFormatted = result.subtitle
          ? result.subtitle.replace(regex, '<strong>$1</strong>')
          : result.subtitle;
        */
        result.subtitleFormatted = result.subtitle;
      } else {
        result.titleFormatted = result.title;
        result.subtitleFormatted = result.subtitle;
      }
      // Add icon if missing
      if (typeof result.icon === 'undefined') {
        result.icon = 'standard:default';
      }
      return result;
    });
    // Add local state and dynamic class to search results
    this.privateFocusedResultIndex = null;
    const self = this;
    this.searchResultsLocalState = this.privateSearchResults.map((result, i) => ({
      result,
      state: {},
      get classes() {
        let cls = 'slds-media slds-listbox__option slds-listbox__option_entity slds-listbox__option_has-meta';
        if (self.privateFocusedResultIndex === i) {
          cls += ' slds-has-focus';
        }
        return cls;
      },
    }));
  }

  @api
  getSelection() {
    return this.privateCurSelection;
  }

  @api
  setDefaultResults(results) {
    this.privateDefaultSearchResults = [...results];
    if (this.privateSearchResults.length === 0) {
      this.setSearchResults(this.privateDefaultSearchResults);
    }
  }

  // INTERNAL FUNCTIONS

  updateSearchTerm(newSearchTerm) {
    this.privateSearchTerm = newSearchTerm;

    // Compare clean new search term with current one and abort if identical
    const newCleanSearchTerm = newSearchTerm.trim().replace(/\*/g, '').toLowerCase();
    if (this.privateCleanSearchTerm === newCleanSearchTerm) {
      return;
    }

    // Save clean search term
    this.privateCleanSearchTerm = newCleanSearchTerm;

    // Ignore search terms that are too small
    if (newCleanSearchTerm.length < this.minSearchTermLength) {
      this.setSearchResults(this.privateDefaultSearchResults);
      return;
    }

    // Apply search throttling (prevents search if user is still typing)
    if (this.privateSearchThrottlingTimeout) {
      clearTimeout(this.privateSearchThrottlingTimeout);
    }
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.privateSearchThrottlingTimeout = setTimeout(() => {
      // Send search event if search term is long enougth
      if (this.privateCleanSearchTerm.length >= this.minSearchTermLength) {
        // Display spinner until results are returned
        this.loading = true;

        const searchEvent = new CustomEvent('search', {
          detail: {
            searchTerm: this.privateCleanSearchTerm,
            rawSearchTerm: newSearchTerm,
            selectedIds: this.privateCurSelection.map((element) => element.id),
          },
        });
        this.dispatchEvent(searchEvent);
      }
      this.privateSearchThrottlingTimeout = null;
    }, SEARCH_DELAY);
  }

  isSelectionAllowed() {
    if (this.isMultiEntry) {
      return true;
    }
    return !this.hasSelection();
  }

  hasSelection() {
    return this.privateCurSelection.length > 0;
  }

  processSelectionUpdate(isUserInteraction) {
    // Reset search
    this.privateCleanSearchTerm = '';
    this.privateSearchTerm = '';
    // Remove selected items from default search results
    const selectedIds = this.privateCurSelection.map((sel) => sel.id);
    let defaultResults = [...this.privateDefaultSearchResults];
    defaultResults = defaultResults.filter((result) => selectedIds.indexOf(result.id) === -1);
    this.setSearchResults(defaultResults);
    // Indicate that component was interacted with
    this.privateIsDirty = isUserInteraction;
    // If selection was changed by user, notify parent components
    if (isUserInteraction) {
      this.dispatchEvent(new CustomEvent('selectionchange', { detail: selectedIds }));
    }
  }

  // EVENT HANDLING

  handleInput(event) {
    // Prevent action if selection is not allowed
    if (!this.isSelectionAllowed()) {
      return;
    }
    this.updateSearchTerm(event.target.value);
  }

  handleKeyDown(event) {
    if (this.privateFocusedResultIndex === null) {
      this.privateFocusedResultIndex = -1;
    }
    if (event.keyCode === KEY_ARROW_DOWN) {
      // If we hit 'down', select the next item, or cycle over.
      this.privateFocusedResultIndex += 1;
      if (this.privateFocusedResultIndex >= this.privateSearchResults.length) {
        this.privateFocusedResultIndex = 0;
      }
      event.preventDefault();
    } else if (event.keyCode === KEY_ARROW_UP) {
      // If we hit 'up', select the previous item, or cycle over.
      this.privateFocusedResultIndex -= 1;
      if (this.privateFocusedResultIndex < 0) {
        this.privateFocusedResultIndex = this.privateSearchResults.length - 1;
      }
      event.preventDefault();
    } else if (event.keyCode === KEY_ENTER
      && this.privateHasFocus
      && this.privateFocusedResultIndex >= 0
    ) {
      // If the user presses enter, and the box is open, and we have used arrows,
      // treat this just like a click on the listbox item
      const selectedId = this.privateSearchResults[this.privateFocusedResultIndex].id;
      this.template.querySelector(`[data-recordid="${selectedId}"]`).click();
      event.preventDefault();
    }
  }

  handleResultClick(event) {
    const recordId = event.currentTarget.dataset.recordid;

    // Save selection
    const selectedItem = this.privateSearchResults.find((result) => result.id === recordId);
    if (!selectedItem) {
      return;
    }
    const newSelection = [...this.privateCurSelection];
    newSelection.push(selectedItem);
    this.privateCurSelection = newSelection;

    // Process selection update
    this.processSelectionUpdate(true);
  }

  handleComboboxMouseDown(event) {
    const mainButton = 0;
    if (event.button === mainButton) {
      this.privateCancelBlur = true;
    }
  }

  handleComboboxMouseUp() {
    this.privateCancelBlur = false;
    // Re-focus to text input for the next blur event
    this.template.querySelector('input').focus();
  }

  handleFocus() {
    // Prevent action if selection is not allowed
    if (!this.isSelectionAllowed()) {
      return;
    }
    this.privateHasFocus = true;
    this.privateFocusedResultIndex = null;
  }

  handleBlur() {
    // Prevent action if selection is either not allowed or cancelled
    if (!this.isSelectionAllowed() || this.privateCancelBlur) {
      return;
    }
    this.privateHasFocus = false;
  }

  handleRemoveSelectedItem(event) {
    if (this.disabled) {
      return;
    }
    const recordId = event.currentTarget.name;
    this.privateCurSelection = this.privateCurSelection.filter((item) => item.id !== recordId);
    // Process selection update
    this.processSelectionUpdate(true);
  }

  handleClearSelection() {
    this.privateCurSelection = [];
    this.privateHasFocus = false;
    // Process selection update
    this.processSelectionUpdate(true);
  }

  handleNewRecordClick(event) {
    const objectApiName = event.currentTarget.dataset.sobject;
    const objectDefaults = event.currentTarget.dataset.defaults;
    this[NavigationMixin.Navigate]({
      type: 'standard__objectPage',
      attributes: {
        objectApiName,
        actionName: 'new',
      },
      state: {
        defaultFieldValues: objectDefaults,
      },
    });
  }

  // STYLE EXPRESSIONS

  get hasResults() {
    return this.privateSearchResults.length > 0;
  }

  get getFormElementClass() {
    return this.variant === VARIANT_LABEL_INLINE
      ? 'slds-form-element slds-form-element_horizontal'
      : 'slds-form-element';
  }

  get getLabelClass() {
    return this.variant === VARIANT_LABEL_HIDDEN
      ? 'slds-form-element__label slds-assistive-text'
      : 'slds-form-element__label';
  }

  get getContainerClass() {
    let css = 'slds-combobox_container slds-has-inline-listbox ';
    if (this.privateHasFocus && this.hasResults) {
      css += 'slds-has-input-focus ';
    }
    if (this.errors.length > 0) {
      css += 'has-custom-error';
    }
    return css;
  }

  get getDropdownClass() {
    let css = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ';
    const isSearchTermValid = this.privateCleanSearchTerm
      && this.privateCleanSearchTerm.length >= this.minSearchTermLength;

    if (this.privateHasFocus
        && this.isSelectionAllowed()
        && (isSearchTermValid || this.hasResults)
    ) {
      css += 'slds-is-open';
    }
    return css;
  }

  get getInputClass() {
    let css = 'slds-input slds-combobox__input has-custom-height ';
    if (this.errors.length > 0 || (this.privateIsDirty && this.required && !this.hasSelection())) {
      css += 'has-custom-error ';
    }
    if (!this.isMultiEntry) {
      css += `slds-combobox__input-value ${(this.hasSelection() ? 'has-custom-border' : '')}`;
    }
    return css;
  }

  get getComboboxClass() {
    let css = 'slds-combobox__form-element slds-input-has-icon ';
    if (this.isMultiEntry) {
      css += 'slds-input-has-icon_right';
    } else {
      css += this.hasSelection() ? 'slds-input-has-icon_left-right' : 'slds-input-has-icon_right';
    }
    return css;
  }

  get getSearchIconClass() {
    let css = 'slds-input__icon slds-input__icon_right ';
    if (!this.isMultiEntry) {
      css += this.hasSelection() ? 'slds-hide' : '';
    }
    return css;
  }

  get getClearSelectionButtonClass() {
    const baseClass = 'slds-button slds-button_icon slds-input__icon slds-input__icon_right';

    return this.hasSelection()
      ? baseClass
      : `${baseClass} slds-hide`;
  }

  get getSelectIconName() {
    return this.hasSelection() ? this.privateCurSelection[0].icon : 'standard:default';
  }

  get getSelectIconClass() {
    return `slds-combobox__input-entity-icon ${(this.hasSelection() ? '' : 'slds-hide')}`;
  }

  get getInputValue() {
    if (this.isMultiEntry) {
      return this.privateSearchTerm;
    }
    return this.hasSelection() ? this.privateCurSelection[0].title : this.privateSearchTerm;
  }

  get getInputTitle() {
    if (this.isMultiEntry) {
      return '';
    }
    return this.hasSelection() ? this.privateCurSelection[0].title : '';
  }

  get getListboxClass() {
    const baseClass = 'slds-listbox slds-listbox_vertical slds-dropdown slds-dropdown_fluid';

    return this.scrollAfterNItems
      ? `${baseClass} slds-dropdown_length-with-icon-${this.scrollAfterNItems}`
      : baseClass;
  }

  get isInputReadonly() {
    if (this.isMultiEntry) {
      return false;
    }
    return this.hasSelection();
  }
}