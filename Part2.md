# LAB

## Part 2: Create and deploy API

1. In VS code, Azure extension, in "Workspace" section click "Create Function..." button.
2. As a project location select "api" directory.
3. Choose JavaScript as a language and HttpTrigger as a trigger.
4. In order to run JS function locally open a terminal, enter "api" dir and type:
```
npm install
npm start
```
5. Check if you can access this url via browser: http://localhost:7071/api/todo/1. Then terminate runtime with Ctrl+C.
6. Replace content of "HttpTrigger1/function.json" with:
```
{
  "bindings": [
    {
      "authLevel": "anonymous",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": [
        "get", "put", "post", "delete"
      ],
      "route": "todo/{id:int?}"
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    }
  ]
}
```
7. Replace content of "HttpTrigger1/index.js" with:
```
const { executeSQL } = require('../shared/utils');

todoREST = function (context, req) {    
    const method = req.method.toLowerCase();
    var payload = null;
    
    switch(method) {
        case "get":
            payload = req.params.id ? { "id": req.params.id } : null;            
            break;
        case "post":
            payload = req.body;            
            break;
        case "put":
            payload =  { 
                "id": req.params.id,
                "todo": req.body
            };   
            break;
        case "delete":
            payload = { "id": req.params.id };
            break;       
    }

    executeSQL(context, method, payload)
}

module.exports = todoREST;
```
8. Create new dir "shared" in "api" dir
9. Create new file "shared/utils.js" and paste the content from "utils.js" file.
10. Edit "local.setting.json" file and inside "Values" paste this content:
```
db_server="YOUR_SERVER_NAME"
db_user="demoadmin"
db_password="Passw0rd1!123"
db_database="tododb"
```
11. Install tedious library for working with Azure SQL database:
```
npm install tedious
```
12. Run function locally and check if GET method is working:
```
npm start
```
enter: http://localhost:7071/api/todo/1
13. Deploy Azure Function to Azure! From VS Code Azure Extension, go to "Resources" section and find your Azure Function. Right mouse click on it and "Deploy to Function App..."
14. Check if GET method work in Azure Function. You can play with another methods (POST, PUT, DELETE) using your REST client.