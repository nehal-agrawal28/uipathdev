import { LightningElement, track, wire, api } from 'lwc';
import getQuoteScheduleInsight from '@salesforce/apex/QuoteScheduleInsightController.getQuoteScheduleInsight';


const columns = [
  { label: 'Applicable', fieldName: 'isApplicable' },
  { label: 'Sequence', fieldName: 'sequence'},
  { label: 'Schedule', fieldName: 'scheduleName' },
  { label: 'Condition Formula', fieldName: 'formula'},
  { label: 'Evaluated Formula', fieldName: 'evaluatedFormula' }
];

export default class quoteScheduleInsight extends LightningElement {

  @api recordId;
  @track data;
  @track columns = columns;
  @track error;

  @wire(getQuoteScheduleInsight, {quoteId: '$recordId' })
  wiredAccounts({error, data }) {
    if (data) {
      console.log('test');
      console.log(data);
      this.data = data;
    } else if (error) {
      this.error = error;
    }
  }
}