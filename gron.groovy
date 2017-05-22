/**
 * File: GrON.groovy
 * Example class to show use of Groovy data interchange format.
 * This is just to show use of Groovy data structure.
 * Actual use of "evaluate()" can introduce a security risk.
 * @sample
 * @author Josef Betancourt
 * @run    groovy GrON.groovy
 *
 * Code below is sample only and is on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied.
 * =================================================
*/
 */
class GrON {
    static def message =
    '''[menu:[id:"file", value:"File",
     popup:[menuitem:[[value:"New", onclick:"CreateNewDoc()"],
     [value:"Open", onclick:"OpenDoc()"], [value:"Close",
     onclick:"CloseDoc()"]]]]]'''
 
    /** script entry point   */
    static main(args) {
       def gron = new GrON()
       // dynamically create object using a String.
       def payload = gron.slurp(this, message)
 
        // manually create the same POGO.
        def obj = [menu:
        [  id: "file",
           value: "File",
                 popup: [
                   menuitem : [
                   [ value: "New", onclick: "CreateNewDoc()" ],
                   [ value: "Open", onclick: "OpenDoc()" ],
                   [ value: "Close", onclick: "CloseDoc()" ]
            ]
           ]
         ]]
 
         // they should have the same String representation.
         assert(gron.burp(payload) == obj.toString())
    }
 
/**
 *
 * @param object context
 * @param data payload
 * @return data object
 */
def slurp(object, data){
    def code = "{->${data}}"  // a closure
    def received = new GroovyShell().evaluate(code)
    if(object){
        received.delegate=object
    }
    return received()
}
 
/**
 *
 * @param data the payload
 * @return data object
 */
def slurp(data){
     def code = "{->${data}}"
     def received = new GroovyShell().evaluate(code)
     return received()
}
 
/**
 * @param an object
 * @return it's string rep
 */
def burp(data){
     return data ? data.toString() : ""
}
 