## Create Empty Function
dotnet new lambda.EmptyFunction --name ApiConsumerFunction
cd ApiConsumerFunction
vi src/ApiConsumerFunction/ApiConsumerFunction.csproj 
vi src/ApiConsumerFunction/Function.cs 

dotnet new lambda.EmptyFunction
dotnet new -i Amazon.Lambda.Templates
dotnet new sln
dotnet sln add src/ApiConsumerFunction/ApiConsumerFunction.csproj

-- build and deploy
cd src
dotnet add package AWSSDK.DynamoDBv2
cd ..
vi src/ApiConsumerFunction/Function.cs 
dotnet clean
dotnet restore
dotnet build
dotnet publish -c Release
cd /Users/aliakkas/apps/aws/lambda/ApiConsumerFunction/src/ApiConsumerFunction/bin/Release/net8.0
cd publish/
zip -r ApiConsumerFunction.zip *
mv *.zip /Users/aliakkas/apps/aws/lambda/ApiConsumerFunction/
cd /Users/aliakkas/apps/aws/lambda/ApiConsumerFunction/
mv ApiConsumerFunction.zip function.zip
terraform init
terraform plan
terraform apply
-- test
aws lambda invoke     --function-name ApiConsumerFunction     --payload '{"body": "{\"name\": \"Cambridge\"}"}'     --cli-binary-format raw-in-base64-out     response.json
cat response.json 
aws lambda invoke     --function-name ApiConsumerFunction     --payload '{"body": "{\"name\": \"Oxford\"}"}'     --cli-binary-format raw-in-base64-out     response.json
cat response.json 

-- may not work
aws lambda create-function \
    --function-name ApiConsumerFunction \
    --runtime dotnet8 \
    --handler "ApiConsumerFunction::ApiConsumerFunction.Function::FunctionHandler" \
    --zip-file fileb://function.zip
