## The Problem

API returns multipage results. We want to get them all. 


## Steps 

The following works with Zendesk but should work for any API. The only changes should be in step 5 and 8

1. create an array to store the results
2. use a do while loop as opposed to a while loop. This makes the logic easy
3. start loop and make the first call with the *first call* url
4. get the result, parse it (assume it is JSON)  and push it in the array
5. modify the url for the next page. This varies from API to API. The example shows Zendesk API. 
6. In Zendesk  the next page url is actually passed in the result. 
7. Once the url is formed - give a 250 ms stop to give the server a bit of rest 
8. loop on while the next page url is not null


## The code example
```javascript
function zd_get (cmd) {
  var url = ZD_BASE+cmd;
  var results =[];
  var service = getService();
  
  if (service.hasAccess()) {
    do {
      try {
        var response = UrlFetchApp.fetch(url, {headers: {'Authorization': 'Bearer ' + service.getAccessToken(),}});
      }
      catch (e) {
        return e;
         
      }
      var result = JSON.parse(response.getContentText());
      results.push(result);
      url = result['next_page'];
      Utilities.sleep(250); // give the server a break
      
    }  while (result['next_page'] !=null);
    return results;
  }
  else return null;

}
```
