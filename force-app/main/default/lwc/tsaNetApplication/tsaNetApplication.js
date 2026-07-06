import { LightningElement, track, api } from 'lwc'

import { subscribe, unsubscribe, isEmpEnabled, onError } from 'lightning/empApi'

import { getCaseInfo } from 'c/tsaNetHelper'

const CASE_UPDATED_CHANNEL = '/event/tsanetconnect__TSANetCaseUpdated__e'

// Safety net: clear a typing indicator if its completion event never arrives.
const TYPING_TIMEOUT_MS = 30000

// How long an outbound send suppresses the typing indicator for its token, in case the
// webhook completion event is delayed or missed.
const SUPPRESS_WINDOW_MS = 60000

export default class TsaNetApplication extends LightningElement {

    @api recordId

    @track state = {}

    @track isLoading = false

    // Tokens of TSANet Cases currently being processed, so the typing indicator is scoped
    // to the specific chat rather than shown on every related case.
    @track typingTokens = []

    @track isNotAccess = false
    @track isUnauthorized = false

    subscription = {}

    // Correlates start/completion events so concurrent webhooks don't clear the indicator early.
    _typingTokens = new Set()
    _typingTimeouts = {}

    // Tokens we just sent on; their incoming webhook is our own outbound message, so the
    // "Someone is typing…" indicator must not be shown for them.
    _suppressedTokens = new Set()
    _suppressTimeouts = {}

    connectedCallback(){
        this.getData()
        this.subscribeToCaseUpdates()
    }

    disconnectedCallback(){
        this.unsubscribeFromCaseUpdates()
        Object.values(this._typingTimeouts).forEach(id => clearTimeout(id))
        Object.values(this._suppressTimeouts).forEach(id => clearTimeout(id))
    }

    getData(showSpinner = true){
        if(showSpinner){
            this.isLoading = true
        }
        getCaseInfo(this.recordId)
        .then(data => this.setData(data))
        .then(() => this.isLoading = false)
        .catch(error => {
            this.isUnauthorized = error?.body?.message == 'Username and password can not be empty!'
            this.isNotAccess = error?.body?.message == 'Insufficient permissions: secure query included inaccessible field'
            this.isLoading = false
        })
    }

    setData(data){
        this.state = data
    }

    handleRefresh(event){
        this.isUnauthorized = false
        this.isNotAccess = false

        // Background refresh skips the blocking page spinner so the user can keep interacting.
        if(event?.detail?.background){
            this.getData(false)
            return
        }

        this.isLoading = false
        this.getData()
    }

    // Subscribes to the platform event so an inbound webhook refreshes this page in real time.
    async subscribeToCaseUpdates(){
        try {
            const enabled = await isEmpEnabled()
            if(!enabled){
                return
            }

            this.subscription = await subscribe(CASE_UPDATED_CHANNEL, -1, response => this.handleCaseUpdate(response))

            onError(error => console.error('TSANet empApi error', error))
        } catch(error){
            console.error('TSANet empApi subscribe failed', error)
        }
    }

    unsubscribeFromCaseUpdates(){
        if(this.subscription?.id){
            unsubscribe(this.subscription, () => {})
        }
    }

    // Routes events for this Case: IsSync=false shows the typing indicator; IsSync=true refreshes.
    // The requestToken identifies the specific TSANet Case so the indicator targets only its chat.
    handleCaseUpdate(response){
        const payload = response?.data?.payload
        const eventCaseId = payload?.tsanetconnect__CaseId__c
        if(!eventCaseId || !this.isSameRecord(eventCaseId)){
            return
        }

        const token = payload?.tsanetconnect__RequestToken__c
        if(!token){
            return
        }

        if(payload?.tsanetconnect__IsSync__c){
            this.stopTyping(token)
            this.clearSuppression(token)
            this.getData(false)
        } else if(!this._suppressedTokens.has(token)){
            // Skip the indicator when this update echoes our own outbound message.
            this.startTyping(token)
        }
    }

    // Records an outbound send so the resulting webhook does not trigger the typing indicator.
    handleNoteSent(event){
        const token = event?.detail?.token
        if(!token){
            return
        }

        this._suppressedTokens.add(token)
        this.stopTyping(token)

        clearTimeout(this._suppressTimeouts[token])
        this._suppressTimeouts[token] = setTimeout(() => this.clearSuppression(token), SUPPRESS_WINDOW_MS)
    }

    clearSuppression(token){
        clearTimeout(this._suppressTimeouts[token])
        delete this._suppressTimeouts[token]
        this._suppressedTokens.delete(token)
    }

    startTyping(token){
        this._typingTokens.add(token)
        this.syncTypingTokens()

        // Auto-clear in case the completion event is missed.
        clearTimeout(this._typingTimeouts[token])
        this._typingTimeouts[token] = setTimeout(() => this.stopTyping(token), TYPING_TIMEOUT_MS)
    }

    stopTyping(token){
        clearTimeout(this._typingTimeouts[token])
        delete this._typingTimeouts[token]
        this._typingTokens.delete(token)
        this.syncTypingTokens()
    }

    // Publishes a fresh array reference so child components react to membership changes.
    syncTypingTokens(){
        this.typingTokens = Array.from(this._typingTokens)
    }

    isSameRecord(eventCaseId){
        return String(eventCaseId).substring(0, 15) === String(this.recordId).substring(0, 15)
    }
}
