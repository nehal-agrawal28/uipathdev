import { api, LightningElement, wire } from 'lwc';

import getManagedContentByTopic from '@salesforce/apex/ContentController_PP.getManagedContentByTopic';

export default class cmsContent extends LightningElement {
    @api topicId;
    @wire( getManagedContentByTopic, { topicId: topicId }) results;

    get jsonData() {
        console.log(JSON.stringify(this.results))
        return this.results
    }
}