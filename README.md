# lambdadotnet
Example of lambda function using dotnet. It demonstrates an implementation of a simple AWS lambda function, which call a REST endpoint and save data in a DynamoDB table. 

## Project
Let's create the complete project structure. Follow these steps:
1. First, create a new directory and navigate to it:
```
mkdir ApiConsumerFunction
cd ApiConsumerFunction
```
2. Create the project using the Lambda template:
```
dotnet new lambda.EmptyFunction
```
If you don't have the Lambda templates installed, install them first:
```
dotnet new -i Amazon.Lambda.Templates
```
3. Create the following directory structure:
```
ApiConsumerFunction/
├── src/
│   └── ApiConsumerFunction/
│       ├── Function.cs
│       └── ApiConsumerFunction.csproj
├── test/
│   └── ApiConsumerFunction.Tests/
│       ├── FunctionTest.cs
│       └── ApiConsumerFunction.Tests.csproj
└── ApiConsumerFunction.sln
```
4. Create the Function.cs file in src/ApiConsumerFunction/:
5. Create the ApiConsumerFunction.csproj file in src/ApiConsumerFunction/:
6. Create the solution file:
```
dotnet new sln
dotnet sln add src/ApiConsumerFunction/ApiConsumerFunction.csproj
```

## build and deploy
```
dotnet build
dotnet publish -c Release
cd src/ApiConsumerFunction/bin/Release/net8.0/publish
zip -r ../../../../../../function.zip *
cd ../../../../../../

use terraform for deploying lambda function
#aws lambda update-function-code --function-name ApiConsumerFunction --zip-file fileb://function.zip
```
## Test
```
aws lambda invoke \
    --function-name ApiConsumerFunction \
    --payload '{"body": "{\"name\": \"Oxford\"}"}' \
    --cli-binary-format raw-in-base64-out \
    response.json
```
### api gateway
```
curl -X POST "${API_ENDPOINT}/search"   -H "Content-Type: application/json" -insecure -d '{"name":"oxford"}'
```
api_endpoint will be printed after "terraform apply" and you make a note of it. 
You need to Set env variable before invoking API_ENDPOINT
 
```
export API_ENDPOINT={result from "terraform apply" command}

## Terraform 
Terraform configuration for the Lambda function:

1. To deploy:
Initialize Terraform:
```
terraform init
```
2. Plan the deployment:
```
terraform plan
```
3. Apply the configuration:
```
terraform apply
```
