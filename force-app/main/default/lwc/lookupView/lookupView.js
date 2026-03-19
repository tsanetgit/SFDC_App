import { LightningElement, api } from 'lwc';
 
export default class LookupView extends LightningElement {

    @api recordId
    @api iconName
    @api value
    @api label

    handleRedirect(){
        window.open('/' + this.recordId, '_blank')
    }
}