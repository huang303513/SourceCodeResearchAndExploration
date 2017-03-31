window.onerror = function(err) {
    log('window.onerror: ' + err)
}

function setupWebViewJavascriptBridge(callback) {
    if (window.WebViewJavascriptBridge) {
        var result = callback(WebViewJavascriptBridge);
        return result;
    }
    if (window.WVJBCallbacks) {
        var result = window.WVJBCallbacks.push(callback);
        return result;
    }
    window.WVJBCallbacks = [callback];
    alert('heh');
    var WVJBIframe = document.createElement('iframe');
    WVJBIframe.style.display = 'none';
    WVJBIframe.src = 'https://__bridge_loaded__';
    document.documentElement.appendChild(WVJBIframe);
    setTimeout(function() {
        document.documentElement.removeChild(WVJBIframe)
    }, 0);
}


var callback = function(bridge) {
    bridge.registerHandler('OC调用JS提供的方法', function(data, responseCallback) {
        //log('OC调用JS方法成功', data)
        var responseData = { 'JS给OC调用的回调': '回调值!' }
        //log('OC调用JS的返回值', responseData)
        responseCallback(responseData)
    })
};

setupWebViewJavascriptBridge(callback);


