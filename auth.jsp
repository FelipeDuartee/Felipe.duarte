


















if (dwr == null) var dwr = {};
if (dwr.auth == null) dwr.auth = {};
if (DWRAuthentication == null) var DWRAuthentication = dwr.auth;






dwr.auth._enabled = false;


dwr.auth._dwrHandleBatchExeption = null;


dwr.auth.enable = function () {
if (dwr.auth._enabled) {
alert("dwr.auth already enabled");
return;
}
dwr.auth._enabled = true;
dwr.auth._dwrHandleBatchExeption = dwr.engine._handleError;
dwr.engine._handleError = dwr.auth.authWarningHandler;
}


dwr.auth.disable = function() {
if (!dwr.auth._enabled) {
alert("dwr.auth not enabled");
return;
}
dwr.engine._handleError = dwr.auth._dwrHandleBatchExeption;
dwr.auth._dwrHandleBatchExeption = null;
dwr.auth._enabled = false;
}


dwr.auth._protectedURL = null;
dwr.auth.setProtectedURL = function(url) {
dwr.auth._protectedURL = url;
}










dwr.auth.defaultAuthenticationRequiredHandler = function(batch,ex) {
alert(ex.message);
return false;
}
dwr.auth._authRequiredHandler = dwr.auth.defaultAuthenticationRequiredHandler;
dwr.auth.setAuthenticationRequiredHandler = function(handler) {
dwr.auth._authRequiredHandler = handler;
}


dwr.auth.defaultAuthenticationFailedHandler = function(login_form) {
alert("Login failed");
return false;
}
dwr.auth._authFailedHandler = dwr.auth.defaultAuthenticationFailedHandler;
dwr.auth.setAuthenticationFailedHandler = function(handler) {
dwr.auth._authFailedHandler = handler;
}



dwr.auth.defaultAccessDeniedHandler = function(batch,ex) {
alert(ex.message);
return false;
}
dwr.auth._accessDeniedHandler = dwr.auth.defaultAccessDeniedHandler;
dwr.auth.setAccessDeniedHandler = function(handler) {
dwr.auth._accessDeniedHandler = handler;
}


dwr.auth.defaultAuthenticationSuccessHandler = function (msg) {
return true;
}
dwr.auth._successHandler = dwr.auth.defaultAuthenticationSuccessHandler;
dwr.auth.setAuthenticationSuccessHandler = function(handler) {
dwr.auth._successHandler = handler;
}



dwr.auth._batch = null;


dwr.auth._deepCopy = function(source) {
var destination = {};
for (property in source) {
var value = source[property];
if (typeof value != 'object') {

destination[property] = value;
}
else if ( value instanceof Array) {





destination[property] = value;
}
else {

destination[property] = dwr.auth._deepCopy(value);
}
}
return destination;
}


dwr.auth._cloneBatch = function(batch) {
var req = batch.req;
var div = batch.div;
var form = batch.form;
var iframe = batch.iframe;
var script = batch.script;
delete batch.req;
delete batch.div;
delete batch.form;
delete batch.iframe;
delete batch.script;
var clone = dwr.auth._deepCopy(batch);
batch.req = req;
batch.div = div;
batch.form = form;
batch.iframe = iframe;
batch.script = script;

clone.completed = false;
clone.map.httpSessionId = dwr.engine._getJSessionId();
clone.map.scriptSessionId = dwr.engine._getScriptSessionId();
return clone;
}

dwr.auth._exceptionPackage = "org.directwebremoting.extend.";

dwr.auth.authWarningHandler = function(batch, ex) {
if (batch == null || typeof ex != "object" || ex.type == null
|| ex.type.indexOf(dwr.auth._exceptionPackage) != 0) {
dwr.auth._dwrHandleBatchExeption(batch, ex);
return;
}

var errorType = ex.type.substring(dwr.auth._exceptionPackage.length);

switch (errorType) {
case "LoginRequiredException":
dwr.auth._batch = dwr.auth._cloneBatch(batch);
if (dwr.auth._authRequiredHandler(batch,ex)) {
dwr.auth._replayBatch();
}
break;
case "AccessDeniedException":
dwr.auth._batch = dwr.auth._cloneBatch(batch);
if (dwr.auth._accessDeniedHandler(batch,ex)) {
dwr.auth._replayBatch();
}
break;
default:
dwr.auth._dwrHandleBatchExeption(batch, ex);
}
}


dwr.auth._replayBatch = function() {
if (dwr.auth._batch == null) {
alert("no batch to replay!");
return;
}
else {

}
var caller = function() {
var batch = dwr.auth._batch;
dwr.auth._batch = null;
dwr.engine._batches[dwr.engine._batches.length] = batch;
dwr.engine._sendData(batch);
};

setTimeout( caller, 200);
}



dwr.auth.ServletLoginProcessor = function() {
var login = null;
var password = null;
this.setLogin = function(aLogin) {
login = aLogin;
}
this.getLogin = function() {
return login;
}
this.setPassword = function(aPassword) {
password = aPassword;
}
this.login = function(login_form) {
login_form.j_username.value = login;
login_form.j_password.value = password;
login_form.submit();

password = null;
}
}

dwr.auth._loginProcessor = new dwr.auth.ServletLoginProcessor();

dwr.auth.authenticate = function(login, password) {
var processor = dwr.auth._loginProcessor;
processor.setLogin(login);
processor.setPassword(password);

var div = document.createElement("div");
div.innerHTML = "<iframe src='"+dwr.auth._protectedURL+"' frameborder='0' width='0' height='0' id='login_frame' name='login_frame' style='width:0px; height:0px; border:0px;'></iframe>";
document.body.appendChild(div);
}

dwr.auth._loginCallback = function(login_form) {
dwr.auth._loginProcessor.login(login_form);
}

dwr.auth._loginFailedCallback = function(login_form) {
dwr.auth._authFailedHandler(login_form);
}

dwr.auth._loginSucceededCallback = function(msg) {
if (dwr.auth._successHandler(msg)) {
dwr.auth._replayBatch();
}
}


