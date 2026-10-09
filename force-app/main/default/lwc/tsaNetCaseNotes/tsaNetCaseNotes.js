import { LightningElement, api, track } from 'lwc'

import { TSANET_CASE_PRIORITIES, RICH_TEXT_FORMATS } from 'c/tsaNetConstants'
import { createTSANetCaseNote, toast, stripRichText } from 'c/tsaNetHelper'

// Collapsible, Messenger-style notes panel for a single TSANet case card.
// Shows a bell with a red count badge; expands to a conversation thread and a composer.
export default class TsaNetCaseNotes extends LightningElement {

    @api count = 0
    @api record
    @api caseSubject
    @api user

    @track _isTyping = false

    // Reactive typing flag: when it turns on, scroll so the indicator is visible at the bottom.
    @api
    get isTyping(){
        return this._isTyping
    }

    set isTyping(value){
        const next = !!value
        if(next && !this._isTyping){
            this._shouldScroll = true
        }
        this._isTyping = next
    }

    @track isOpen = false
    @track message = ''
    @track isRichText = false

    // Server-backed notes and locally-added optimistic notes shown before the server confirms.
    @track _serverNotes = []
    @track _pendingNotes = []
    _shouldScroll = false

    // Reactive notes setter: flags an auto-scroll whenever a new message arrives
    // (user-created or webhook-driven) so the latest message stays in view.
    @api
    get notes(){
        return [...this._serverNotes, ...this._pendingNotes]
    }

    set notes(value){
        const next = value || []
        if(next.length > this._serverNotes.length){
            this._shouldScroll = true
        }
        this._serverNotes = next

        // The server now reflects any confirmed sends; drop optimistic notes that succeeded
        // so they are not shown twice. Still-sending and failed notes remain visible.
        if(this._pendingNotes.length){
            this._pendingNotes = this._pendingNotes.filter(note => note.status !== 'sent')
        }
    }

    renderedCallback(){
        if(this.isOpen && this._shouldScroll){
            this.scrollToBottom()
            this._shouldScroll = false
        }
    }

    // Scrolls the conversation thread to the most recent message.
    scrollToBottom(){
        const thread = this.template.querySelector('.notes__thread')
        if(thread){
            thread.scrollTop = thread.scrollHeight
        }
    }

    // Toggles the conversation thread open/closed; scroll to latest when opening.
    handleToggle(){
        this.isOpen = !this.isOpen
        if(this.isOpen){
            this._shouldScroll = true
        }
    }

    handleChangeMessage(event){
        this.message = event?.target?.value
    }

    // Switches between the default single-line plain input and the rich text editor.
    handleToggleRichText(){
        // Leaving rich text: strip formatting so the plain input does not show raw HTML.
        if(this.isRichText){
            this.message = this.plainMessage
        }
        this.isRichText = !this.isRichText
    }

    // Plain mode: Enter sends. Rich text keeps Enter for new lines; send with Ctrl/Cmd + Enter.
    handleKeyDown(event){
        if(event.key !== 'Enter'){
            return
        }
        const sendCombo = this.isRichText ? (event.ctrlKey || event.metaKey) : !event.shiftKey
        if(sendCombo){
            event.preventDefault()
            this.handleSend()
        }
    }

    // Optimistic send: the message appears immediately as "Sending…", then the API runs in the
    // background and the status is updated (or rolled back on failure).
    handleSend(){
        if(this.isSendDisabled){
            return
        }

        // Description is the rich text (HTML) the user typed.
        const description = this.message
        const clientKey = `pending-${Date.now()}`

        this.addPendingNote(clientKey, description)
        this.message = ''
        this._shouldScroll = true

        // Summary defaults to the Case Subject so it is not shown separately in the thread.
        const json = JSON.stringify({
            summary: this.caseSubject,
            description: description,
            priority: TSANET_CASE_PRIORITIES.MEDIUM,
            submittedBy: {
                firstName: this.user?.FirstName,
                lastName: this.user?.LastName
            }
        })

        createTSANetCaseNote(this.token, json).then(() => {
            this.updatePendingStatus(clientKey, 'sent', 'Sent')
            // Tell the page this token is an outbound send so the typing indicator is suppressed.
            this.dispatchEvent(new CustomEvent('notesent', { detail: { token: this.token }}))
            // Background refresh: the message is already shown, so don't block the page with a spinner.
            this.dispatchEvent(new CustomEvent('refresh', { detail: { background: true }}))
        }).catch(error => {
            this.updatePendingStatus(clientKey, 'failed', 'Not sent')
            this.message = description
            toast(this, 'Error', 'error', error?.body?.message || 'Unable to send the note.')
        })
    }

    // Builds an outbound chat bubble for a message that has not yet been confirmed by the server.
    addPendingNote(clientKey, description){
        const sender = [this.user?.FirstName, this.user?.LastName].filter(Boolean).join(' ').trim()

        this._pendingNotes = [...this._pendingNotes, {
            key: clientKey,
            createdAt: new Date().toISOString(),
            sender,
            initials: this.getInitials(sender),
            companyName: this.record?.tsanetconnect__SubmittedCompanyName__c,
            summary: this.caseSubject,
            showSummary: false,
            description,
            isStandard: false,
            alignRight: false,
            rowClass: 'note-row note-row_inbound',
            bubbleClass: 'note-bubble note-bubble_inbound',
            status: 'sending',
            statusLabel: 'Sending…',
            statusClass: 'note-row__status',
            isFailed: false
        }]
    }

    // Updates an optimistic note's delivery status in place.
    updatePendingStatus(clientKey, status, statusLabel){
        const statusClass = status === 'failed' ? 'note-row__status note-row__status_failed' : 'note-row__status'
        this._pendingNotes = this._pendingNotes.map(note =>
            note.key === clientKey
                ? { ...note, status, statusLabel, statusClass, isFailed: status === 'failed' }
                : note
        )
    }

    // Derives up-to-two-letter initials from a name for the chat avatar.
    getInitials(name){
        if(!name){ return '?' }
        const parts = name.trim().split(/\s+/)
        const first = parts[0]?.charAt(0) || ''
        const last = parts.length > 1 ? parts[parts.length - 1].charAt(0) : ''
        return (first + last).toUpperCase()
    }

    get token(){
        return this.record?.tsanetconnect__Token__c
    }

    get hasNotes(){
        return this.notes && this.notes.length > 0
    }

    get hasCount(){
        return this.count > 0
    }

    get countLabel(){
        return this.count > 99 ? '99+' : String(this.count)
    }

    // Composer is shown only for cases that currently accept notes.
    get showComposer(){
        return this.record?.isNoteable
    }

    get toggleIcon(){
        return this.isOpen ? 'utility:chevronup' : 'utility:chat'
    }

    get toggleAltText(){
        return this.isOpen ? 'Hide notes' : 'Show notes'
    }

    get richTextFormats(){
        return RICH_TEXT_FORMATS
    }

    // Rich text returns HTML; strip tags/entities to detect an effectively empty message.
    get plainMessage(){
        return stripRichText(this.message)
    }

    get isSendDisabled(){
        return !this.plainMessage
    }

    get composerClass(){
        return this.isRichText ? 'composer composer_rich' : 'composer composer_plain'
    }

    get formatButtonClass(){
        return this.isRichText ? 'composer__format composer__format_active' : 'composer__format'
    }

    get formatToggleTitle(){
        return this.isRichText ? 'Switch to plain text' : 'Switch to rich text'
    }

    get sendTitle(){
        return this.isRichText ? 'Send (Ctrl/Cmd + Enter)' : 'Send (Enter)'
    }
}
