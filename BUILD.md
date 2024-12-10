## Create Empty Function
### initial setup
```
install dotnet
dotnet new lambda.EmptyFunction
dotnet new -i Amazon.Lambda.Templates
dotnet new sln
dotnet sln add src/ApiConsumerFunction/ApiConsumerFunction.csproj
```
### implement logic
```
dotnet new lambda.EmptyFunction --name ApiConsumerFunction
cd ApiConsumerFunction
vi src/ApiConsumerFunction/ApiConsumerFunction.csproj 
vi src/ApiConsumerFunction/Function.cs 
```
### build and deploy
```
cd src
dotnet add package AWSSDK.DynamoDBv2
cd ..
vi src/ApiConsumerFunction/Function.cs 
dotnet clean
dotnet restore
dotnet build
dotnet publish -c Release
cd ./src/ApiConsumerFunction/bin/Release/net8.0
cd publish/
zip -r ApiConsumerFunction.zip *
mv ApiConsumerFunction.zip function.zip
terraform init
terraform plan
terraform apply

### test
- aws lambda invoke --function-name ApiConsumerFunction --payload '{"body": "{\"name\": \"Cambridge\"}"}' --cli-binary-format raw-in-base64-out response.json
  - verify result -> cat response.json 
- aws lambda invoke --function-name ApiConsumerFunction --payload '{"body": "{\"name\": \"Oxford\"}"}' --cli-binary-format raw-in-base64-out response.json
  - verify result -> cat response.json 
