import { LightningElement, api } from 'lwc';

export default class TsaNetCaseCard extends LightningElement {

    @api record
    @api state
    @api user
    @api typingTokens = []

    // Forward action events from the shared actions component up to the related list.
    // Preserves the background flag so post-send refreshes stay silent.
    handleRefresh(event){
        this.dispatchEvent(new CustomEvent('refresh', { detail: event?.detail }))
    }

    handleOnLoading(event){
        this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: event?.detail?.isLoading }}))
    }

    // Forward the outbound-send signal up so the page can suppress the typing indicator for this token.
    handleNoteSent(event){
        this.dispatchEvent(new CustomEvent('notesent', { detail: { token: event?.detail?.token }}))
    }

    get status(){
        return this.record?.tsanetconnect__Status__c;
    }

    get member(){
        return this.record?.tsanetconnect__Partner__c;
    }

    get contact(){
        return this.record?.tsanetconnect__TSANetContact__c;
    }

    get email(){
        return this.record?.tsanetconnect__TSANetEmail__c;
    }

    get requestDate(){
        return this.record?.tsanetconnect__RequestDate__c;
    }

    get priority(){
        return this.record?.tsanetconnect__Priority__c;
    }

    get direction(){
        return this.record?.tsanetconnect__Direction__c;
    }

    get priorityStyleClass() {
        return `slds-m-right_xx-small ${this.record?.priorityBadgeClass}`;
    }

    get statusStyleClass() {
        return `slds-m-right_small ${this.record?.statusBadgeClass}`;
    }

    get notes(){
        return this.record?.notes || [];
    }

    get notesCount(){
        return this.record?.notesCount || 0;
    }

    get caseSubject(){
        return this.state?.caseRecord?.Subject;
    }

    get userInfo(){
        return this.user || this.state?.user;
    }

    // True only when a webhook is processing this specific TSANet Case (matched by token),
    // so the "Someone is typing…" indicator stays scoped to its own chat.
    get isTyping(){
        const token = this.record?.tsanetconnect__Token__c;
        return !!token && this.typingTokens?.includes(token);
    }
}
