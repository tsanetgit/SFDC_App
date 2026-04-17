import { LightningElement, api, track } from 'lwc';
import searchUsers from '@salesforce/apex/UserLookupController.searchUsers';
import getUserById from '@salesforce/apex/UserLookupController.getUserById';

export default class UserLookup extends LightningElement {
    @api label = 'User';
    @api placeholder = 'Search user...';
    @api required = false;

    _value;
    @api
    get value() { return this._value; }
    set value(v) {
        this._value = v;
        // якщо передали значення — підвантажуємо картку
        if (v) this.loadPreselected(v);
        else this.clearSelection();
    }

    @track results = [];
    @track selectedUser = null;
    @track searchTerm = '';
    @track showDropdown = false;
    @track isLoading = false;
    message;

    get notLoading() { return !this.isLoading; }

    connectedCallback(){
        if (this._value && !this.selectedUser) {
        this.loadPreselected(this._value);
        }
    }

    async loadPreselected(userId){
        try {
            const u = await getUserById({ userId });
            if (u){
                this.selectedUser = u;
                this.dispatchEvent(new CustomEvent('select', { detail: { value: u.id, user: u }}));
            }
        } catch(e){
            console.error(e);
        }
    }


    onInputChange(e){
        this.searchTerm = e.target.value;
        this.debouncedSearch();
    }

    onFocus(){
        this.showDropdown = true;
        if (this.results.length === 0 && !this.searchTerm) {
            this.debouncedSearch();
        }
    }

    onBlur(){
        setTimeout(()=>{ this.showDropdown = false; }, 150);
    }

    async doSearch(){
        this.isLoading = true;
        this.message = undefined;
        try {
            const res = await searchUsers({ searchTerm: this.searchTerm, limitSize: 10 });
            this.results = res ?? [];
        } catch(err){
            this.message = 'Search Error';

            console.error(err);
            this.results = [];
        } finally{
            this.isLoading = false;
        }
    }

    debouncedSearch = (() => {
        let timer;
        return () => {
        clearTimeout(timer);
        timer = setTimeout(() => this.doSearch(), 250);
        };
    })();

    handleSelect(e){
        const id = e.currentTarget.dataset.id;
        const u = this.results.find(x => x.id === id);
        if (u){
        this.selectedUser = u;
        this.showDropdown = false;
        this.dispatchEvent(new CustomEvent('select', { detail: { value: u.id, user: u }}));
        }
    }

    clearSelection(){
        this.selectedUser = null;
        this.searchTerm = '';
        this.results = [];
        //this.dispatchEvent(new CustomEvent('clear'));
    }

    @api
    get valueId(){
        return this.selectedUser ? this.selectedUser.id : null;
    }

    @api
    setSelected(userRecord){
        this.selectedUser = userRecord || null;
    }

    @api
    validate(){
        if (this.required && !this.selectedUser){
        this.message = 'Required field';
        return { isValid: false, errorMessage: this.message };
        }
        this.message = undefined;
        return { isValid: true };
    }
}