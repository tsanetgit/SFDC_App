import { LightningElement, api } from 'lwc';

import {
    USER_NAME_FIELD,
    USER_FIRST_NAME_FIELD,
    USER_LAST_NAME_FIELD,
    USER_EMAIL_FIELD,
    USER_PHONE_FIELD,
    USER_MOBILE_PHONE_FIELD,
} from 'c/tsaNetConstants'

export default class TsaNetActionModalViewForm extends LightningElement {

    @api state
    @api record

    get caseRecord(){
        return this.state?.caseRecord
    }

    get caseNumber(){
        return this.state?.caseRecord?.CaseNumber
    }

    get caseLink(){
        return '/' + this.state?.caseRecord?.Id
    }

    get companyName() {
        return this.record?.tsanetconnect__receivedCompanyName__c ?? '';
    }

    get ownerLink(){
        return '/' + this.state?.caseRecord?.Owner?.Id
    }

    get ownerName() {
        return this.caseRecord?.Owner?.Name ?? this.userName;
    }

    get ownerEmail() {
        return this.caseRecord?.Owner?.Email ?? this.userEmail;
    }

    get ownerPhone() {
        return this.caseRecord?.Owner?.Phone ?? this.userPhone;
    }

    get userFirstName() {
        return this.state?.user[USER_FIRST_NAME_FIELD.fieldApiName] ?? '';
    }

    get userLastName() {
        return this.state?.user[USER_LAST_NAME_FIELD.fieldApiName] ?? '';
    }

    get userName() {
        return this.state?.user[USER_NAME_FIELD.fieldApiName] ?? '';
    }

    get userEmail() {
        return this.state?.user[USER_EMAIL_FIELD.fieldApiName] ?? '';
    }

    get userPhone() {
        return (
            this.state?.user[USER_PHONE_FIELD.fieldApiName] ??
            this.state?.user[USER_MOBILE_PHONE_FIELD.fieldApiName] ??
            ''
        );
    }
}