import { LightningElement, api } from 'lwc';

export default class TierSelect extends LightningElement {

    @api field

    @api options

    data = new Set()
    children = []
    value

    childCound = 0
    currentLevel = 0

    result = ''

    handleChangeSelect(event){
        this.value = event.target.value

        if(this.children.length > 0){
            this.children = []
            this.data = new Set()
            this.childCound = 0
        }

        const found = this.options.find(o => ( o.value == this.value ))
        this.data.add(found)
        this.setResult()

        if(found && found?.children && found?.children.length){
            const options = found?.children.map(c => ({ label: c.value, value: c.value, children: c.children }))
            const child = {}
            child['options'] = options
            child['parentValue'] = this.value
            this.childCound = 0
            this.currentLevel = 1;
            this.children = [...this.children, child]
        }
    }

    handleChangeSelectChild(event){
        const childValue = event.target.value

        const found = this.children[this.childCound].options.find(c => ( c.value == childValue ))

        if(found){

            this.children.length = this.childCound + 1
            const array = [...this.data];
            array.length = this.childCound  + 1
            this.data = new Set(array)

            this.data.add(found)
            this.setResult()

            this.children[this.childCound].value = childValue

            if(found && found?.children && found?.children.length){
                const options = found?.children.map(c => ({ label: c.value, value: c.value, children: c.children }))
                const child = {}
                child['options'] = options
                child['parentValue'] = childValue
                this.children = [...this.children, child]
                this.childCound = this.childCound + 1
            }
        } else {
            let count = 0
            let splitNumber = 0
            this.children.forEach(el => {
                if(el.parentValue == childValue){
                    splitNumber = count;
                }
                count++;
            })

            this.children.length = splitNumber + 1

            const array = [...this.data];

            array.length = splitNumber  + 1
            this.data = new Set(array)

            const found2 = this.children[splitNumber].options.find(c => ( c.value == childValue ))


            this.data.add(found2)
            this.setResult()

            if(found2 && found2?.children && found2?.children.length){
                const options = found2?.children.map(c => ({ label: c.value, value: c.value, children: c.children }))
                const child = {}
                child['options'] = options
                child['parentValue'] = childValue
                this.children = [...this.children, child]
                this.childCound = splitNumber + 1
            }

        }
    }

    setResult(){
        let res = ''
        this.data.forEach(e => {
            res += ( e.value + ':' )
        })

        res = res.substring(0, res.length - 1);

        this.result = res

        this.dispatchEvent(new CustomEvent("select", { detail: { label: this.field.label, value: res } }))
    }
}