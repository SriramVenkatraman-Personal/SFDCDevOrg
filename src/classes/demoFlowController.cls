public class demoFlowController {

    private final String baseUrl; // Base URL used for every POST/PATCH
    private final String flowName { get; set; } // Name of the flow
    public String flowLabel { get; set; } // Label of the flow
    private String guid; // Guid of the current interview
    public Map<String, Object> resultMap { get; set; } // Builds JSON for POST/PATCH calls
    
    /* These boolean variables track whether each action butotn is needed */
    public boolean hasBack { get; set; }
    public boolean hasPause { get; set; }
    public boolean hasResume { get; set; }
    public boolean hasFinish { get; set; }
    public boolean hasStartOver {get; set;}
    
    public List<Screen> screens {get; set;} // List of screens visible on the current page
    public List<List<Screen>> pages {get; set;} // List of the previous lists of screens, one per page
    public string chosenScreen {get; set;} // Screen that was clicked on
    public screen currentScreen {get; set;} // Screen that was generated most recently
    
    public boolean newScreenPresent {get; set;}
    
    /* Constructor initializes lists, gets flow from URL parameter, and sets baseURL,
      then makes the initial POST call and sets necessary variables for first screen */
    public demoFlowController() {
        pages = new List<List<Screen>>();
        screens = new List<Screen>();
        currentScreen = new Screen();
        flowName = ApexPages.currentPage().getParameters().get('flow');
        // flowName = 'Tip_Calculator'; //'Survey_Customers';
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v36.0/process/';
        POST();
        setAll();
        newScreenPresent = false;
    }
    
    /* These next 5 methods make the specified PATCH calls and then set the necessary variables so the screens are displayed correctly */
    public PageReference next() {
        System.debug('clicked next');
        adjustCurrentScreen(chosenScreen); // If Next was clicked on a screen other than the most current one, adjusts "screens" list
        PATCH('NEXT');
        setAll();
        return null;
    }
    
    public PageReference pause() {
        adjustCurrentScreen(chosenScreen);
        PATCH('PAUSE');
        setAll();
        return null;
    }
    
    public PageReference resume() {
        PATCH('RESUME');
        setAll();
        return null;
    }
    
    public PageReference finish() {
        PATCH('FINISH');
        setAll();
        return null;
    }
    
    public PageReference startOver() {
        screens = new List<Screen>(); // Reinitializes variables to start over
        pages = new List<List<Screen>>(); 
        POST();
        setAll();
        return null;
    }
    
    /* Moves back a visible page, but doesn't make any Back calls to API */
    public PageReference back() {
        screens = pages.remove(pages.size() - 1); // Updates list of screens to display previous page
        currentScreen = screens.get(screens.size() - 1); // Sets currentScreen to final screen on the current page
        setActions(); // Adjust button booleans
        return null;
    }
    
    /* If the user has moved back screens, adjusts screens list */
    public void adjustCurrentScreen(string screenName){
        System.debug('Adjusting screens');
        while(!screenName.equals(currentScreen.screenName)) { // While the last screen in the list isn't the one the user clicked on...    
            screens.remove(screens.size() - 1); // ...removes the last the last screen
            currentScreen = screens.get(screens.size() - 1); // ...keeps "currentScreen" updated
        }
        return;
    }
    
    private void setAll() {
        setFields();
        setActions();
        setError();  
    }
    
    /* Makes initial POST call */
    public void POST() {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + 'interviews/' + flowName); // Builds URL
        req.setMethod('POST');

        String authorizationHeader = 'Bearer ' + UserInfo.getSessionId(); // Sets necessary headers
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        req.setHeader('Accept', 'application/json');
        req.setBody('[]');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        String j = res.getBody(); // Stores JSON response
        /* Removes the square brackets to make it plain JSON that can be interpreted in setResult.
            Necessary because JSON is currently returned as one element in a list. */
        j = j.removeStart('[');
        j = j.removeEnd(']');
        setResult(j);
    }

    /* Handles all PATCH calls */
    private void PATCH(String action) {
        System.debug('in patch');
        Map<String, Object> screenInputs = new Map<String, Object>();

        Screen s = currentScreen;
        
        /* Builds inputs for the PATCH call */
        for (OneField field : s.fields) { // Loops through fields, placing non-null inputs into request Map
            if ((field.fieldType.equals('RADIO_BUTTONS') || field.fieldType.equals('DROPDOWN')) && field.oneSelected != null) {
                screenInputs.put(field.name + '.' + field.oneSelected + '.selected', 'true');
            } else if (field.selected != null && field.selected.size() > 0) {
                for (String c : field.selected) {
                    screenInputs.put(field.name + '.' + c + '.selected', 'true');
                }
            } else if (field.fieldType == 'INPUT' && field.dataType == 'BOOLEAN') {
                if (!field.boolValue) {
                    screenInputs.put(field.name, 'false');
                } else {
                    screenInputs.put(field.name, 'true');
                }                
            } else if (field.dataType == 'DATEONLY') {
                if(field.value == '')
                    screenInputs.put(field.name, date.today());
                else
                    screenInputs.put(field.name, date.parse(field.value));
            } else if (field.value != null) {
                screenInputs.put(field.name, field.value);
            } 
        }
        
        /* Sets up URL, method, and headers for request */
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + 'interviews/' + flowName + '/' + guid + '?_HttpMethod=PATCH');
        req.setMethod('POST');
        String authorizationHeader = 'Bearer ' + UserInfo.getSessionId();
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        req.setHeader('Accept', 'application/json');
        
        /* Inserts inputs into final REST call, which has shape {"inputs":[{...inputs...}]}, so it needs to be placed in a List before being mapped to "inputs" keyword */
        Map<String, Object> requestMap = new Map<String, Object>();
        requestMap.put('screenInputs', screenInputs);
        requestMap.put('action', action); // Records the action that was selected
        requestMap.put('state', s.state); // Record state ID of the current screen
        req.setBody(JSON.serialize(requestMap));
        
        System.debug(screenInputs);
        
        Http h = new Http();
        HTTPResponse res = h.send(req);
        String j = res.getBody();
        j = j.removeStart('[');
        j = j.removeEnd(']');
        setResult(j);
    }
    
    /* Sets any errors that apply to the entire screen (e.g. NOT errors for individual field validation) */
    private void setError() {
        List<Object> errorList = (List<Object>) resultMap.get('errorMessages');
        if (errorList != null && errorList.size() > 0) {
            screens.get(screens.size() - 1).error = (String) errorList.get(0);
        }
    }
    
    /* Parses returned JSON and sets the variables for the new screen */
    private void setResult(String response) {
        Screen s = new Screen();
        
        /* Retrieves variables from JSON */
        resultMap = (Map<String, Object>) JSON.deserializeUntyped(response);
        
        if(resultMap.containsKey('message')) {
            screens.get(screens.size()-1).error = (String) resultMap.get('message');
            return;
        }
        
        flowLabel = (String) resultMap.get('flowLabel');
        guid  = (String) resultMap.get('guid');
        s.screenName = (String) resultMap.get('screenName');
        s.actions = (List<Object>) resultMap.get('availableActions');
        s.state = (String) resultMap.get('state');
        
        if (resultMap.get('interviewStatus') == null) { // Checks for errors
            return;
        }
        if (((String) resultMap.get('interviewStatus')).equals('FINISHED')) { // This screen would normally have the same name as the previous screen, but that would give unwanted behavior
            s.screenName = 'Finished';
        }
        /* If the previous screen had errors, the new screen has the same name. */
        if (s.screenName.equals(currentScreen.screenName)) { // Checks if the new screen has the same name as the previous screen
            screens.set(screens.size() - 1, s);// Replaces previous screen with new screen
            currentScreen = s;
        /* Handle normal screens */
        } else {
            currentScreen.removeErrors();// Removes error messages from the screen so that the user doesn't see errors that have been fixed already
            currentScreen = s;
            if(currentScreen.screenName.substringBefore('_') == 'New'){// Checks for flag to start new page
                pages.add(screens);// Stores current page
                screens = new List<Screen>();//Begins new page
            }
            screens.add(s);// Adds new screen to page
        }
    }
    
    /* Parses the JSON to find the necessary information to display the fields correctly */
    private void setFields() {
        if(resultMap.containsKey('message')) {
            return;
        }    
    
        if (resultMap.get('screenFields') == null) {// This happens when the flow has been paused
            return;
        }
        Screen s = screens.get(screens.size() - 1);
        s.fields = new List<OneField>();
        for (Object o : (List<Object>) resultMap.get('screenFields')) {// Stores information about each field
            Map<String, Object> field = (Map<String,Object>) o;
            OneField f = new OneField();
            
            f.name         = (string) field.get('name');
            f.dataType     = (string) field.get('dataType');
            f.field        = (string) field.get('label');
            f.fieldType    = (string) field.get('fieldType');
            f.invalidValue = (string) field.get('invalidValue');
            if (field.get('value') != null) {
                if (f.dataType.equals('CURRENCY')) {
                    Map<String, Object> curr = (Map<String, Object>) field.get('value');
                    Object val = curr.get('valueForDisplay');
                    f.value = (String) val;
                } else if (f.dataType.equals('BOOLEAN')) {
                    f.value = String.valueOf(field.get('value'));
                    f.boolValue = Boolean.valueOf(field.get('value'));
                } else {
                    f.value = String.valueOf(field.get('value')).unescapeHtml4();
                }
            }
            f.isRequired   = (boolean) field.get('isRequired');
            f.errors       = (List<Object>) field.get('errorMessages');
            if (f.errors != null && f.errors.size() > 0) {// If the screen had errors, the fields have error messages
                f.error = (String) f.errors.get(0);
            }
            
            if (field.get('choices') != null) {// Handles radio buttons, drop-down lists, etc.
                f.choices = new List<SelectOption>();
                f.selected = new List<String>();
                for (Object ob : (List<Object>) field.get('choices')) {
                    Map<String, Object> choice = (Map<String, Object>) ob;
                    f.choices.add(new SelectOption((String) choice.get('name'), (String) choice.get('label')));
                    if (choice.get('isSelected').equals('true')) {
                        f.selected.add((String) choice.get('name'));
                        f.oneSelected = (String) choice.get('name'); 
                    }
                }
            }
            if (f.fieldType.equals('INPUT')) {// INPUT "fieldtype" is divided into many "data_types", such as dates and checkboxes 
                f.textFieldType = getType(f);
            }
            s.fields.add(f);
        }
    }
    
    /* Determines which buttons to display on this screen */
    private void setActions() {
        Integer count = 0;
        for(Screen t : screens) {
            if(t.screenName.contains('New_'))
                count++;
        }
        for(Screen t : pages.get(pages.size() - 1)) {
            if(t.screenName.contains('New_'))
                count++;
        }
        if(count > 1) 
            newScreenPresent = true;
        else
            newScreenPresent = false;
        Screen s = screens.get(screens.size() - 1);
        s.hasNext = false;
        hasBack = false;
        hasFinish = false;
        hasPause = false;
        hasResume = false;
        if (s.actions == null) {
            hasStartOver = true;
            return;
        }
        for (Object a : s.actions) {
            if (((String) a).equalsIgnoreCase('next'))
                s.hasNext = true;
            if (((String) a).equalsIgnoreCase('finish'))
                hasFinish = true;
            if (((String) a).equalsIgnoreCase('pause'))
                hasPause = true;
            if (((String) a).equalsIgnoreCase('resume')) 
                hasResume = true;
            if (((String) a).equalsIgnoreCase('back') && newScreenPresent == true)
                hasBack = true;
        }
        hasStartOver = s.actions.isEmpty();
    }
    
    private void clearErrors() {
        currentScreen.removeErrors();
    }
    
    /* Clarifies what kind of 'INPUT' the field is */
    private String getType(OneField f) {
        if (f.dataType == 'DATEONLY') { // Date field
            return 'date';
        } else if (f.dataType == 'BOOLEAN') { // Checkbox field
            return null;
        } else {
            return 'text'; // Any other input field
        }
    }
    
    /* Specification for one screen */
    public class Screen
    {
        public string screenName {get; set;}
        public List<OneField> fields {get; set;}
        public List<Object> actions {get; set;}
        public String error {get; set;}
        private String state {get; set;}
        public boolean hasNext { get; set; }
        
        public Screen() {
            fields = new List<OneField>();
            actions = new List<Object>();
        }
        
        public void removeErrors() {
            error = null;
            for (OneField f : fields) {
                f.errors = null;
                f.error = null;
            }
        }
    }
    
    /* Specification for one field */
    public class OneField
    {
        public string name {get; set;} // Unique name
        public string dataType {get; set;}
        public string field {get; set;}// Label to be displayed to the user
        public string fieldType {get; set;}
        public string invalidValue {get; set;}
        public boolean isRequired {get; set;}
        public string value {get; set;}
        public List<SelectOption> choices {get; set;}
        public List<String> selected {get; set;}
        public List<Object> errors {get; set;}
        public string error {get; set;}
        
        public string textFieldType {get; set;}
        public string oneSelected {get; set;}
        public boolean boolValue {get; set;}
    }
    
}