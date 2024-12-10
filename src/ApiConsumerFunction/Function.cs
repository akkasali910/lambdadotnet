using System.Net.Http;
using System.Text.Json;
using Amazon.Lambda.Core;
using Amazon.Lambda.APIGatewayEvents;
using Amazon.DynamoDBv2; 
using Amazon.DynamoDBv2.Model;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace ApiConsumerFunction;

public class Function
{
    private static readonly HttpClient httpClient = new();
    private static readonly IAmazonDynamoDB dynamoDbClient = new AmazonDynamoDBClient();
    private const string API_URL = "https://api.england-rfu.com/fixtures-and-results/search";
    private const string TABLE_NAME = "api_responses";

    public class ApiResponse
    {
        public required string Id { get; set; }
        public required string SearchTerm { get; set; }
        public required string Response { get; set; }
        public DateTime Timestamp { get; set; }
    }

    public async Task<APIGatewayProxyResponse> FunctionHandler(APIGatewayProxyRequest request, ILambdaContext context)
    {
        try
        {
            context.Logger.LogInformation("Function execution started");
            var name = ExtractNameFromRequest(request, context);
            var apiResponse = await CallExternalApi(name, context);
            await SaveToDynamoDB(name, apiResponse, context);
            
            return new APIGatewayProxyResponse
            {
                StatusCode = 200,
                Body = apiResponse,
                Headers = GetCommonHeaders()
            };
        }
        catch (HttpRequestException ex)
        {
            context.Logger.LogError($"HTTP Request Error: {ex.Message}");
            return CreateErrorResponse(
                statusCode: ex.StatusCode != null ? (int)ex.StatusCode : 500,
                message: "API request failed"
            );
        }
        catch (AmazonDynamoDBException ex)
        {
            context.Logger.LogError($"DynamoDB Error: {ex.Message}");
            return CreateErrorResponse(
                statusCode: 500,
                message: "Database operation failed"
            );
        }
        catch (Exception ex)
        {
            context.Logger.LogError($"Error: {ex.Message}");
            return CreateErrorResponse(
                statusCode: 500,
                message: "Internal server error"
            );
        }
    }

    private static string ExtractNameFromRequest(APIGatewayProxyRequest request, ILambdaContext context)
    {
        if (string.IsNullOrEmpty(request?.Body))
        {
            return "Oxford";
        }

        try
        {
            var jsonDocument = JsonDocument.Parse(request.Body);
            if (jsonDocument.RootElement.TryGetProperty("name", out JsonElement nameElement))
            {
                return nameElement.GetString() ?? "Oxford";
            }
        }
        catch (JsonException ex)
        {
            context.Logger.LogError($"Error parsing JSON: {ex.Message}");
            throw;
        }

        return "Oxford";
    }

    private async Task<string> CallExternalApi(string name, ILambdaContext context)
    {
        var apiUrl = $"{API_URL}?name={Uri.EscapeDataString(name)}";
        context.Logger.LogInformation($"Calling API: {apiUrl}");

        var response = await httpClient.GetAsync(apiUrl);
        response.EnsureSuccessStatusCode();
        
        var content = await response.Content.ReadAsStringAsync();
        context.Logger.LogInformation($"API Response received. Length: {content.Length}");
        
        return content;
    }

    private async Task SaveToDynamoDB(string searchTerm, string response, ILambdaContext context)
    {
        var apiResponse = new ApiResponse
        {
            Id = Guid.NewGuid().ToString(),
            SearchTerm = searchTerm,
            Response = response,
            Timestamp = DateTime.UtcNow
        };

        var request = new PutItemRequest
        {
            TableName = TABLE_NAME,
            Item = new Dictionary<string, AttributeValue>
            {
                { "id", new AttributeValue { S = apiResponse.Id } },
                { "search_term", new AttributeValue { S = apiResponse.SearchTerm } },
                { "response", new AttributeValue { S = apiResponse.Response } },
                { "timestamp", new AttributeValue { S = apiResponse.Timestamp.ToString("o") } }
            }
        };

        context.Logger.LogInformation($"Saving response to DynamoDB for search term: {searchTerm}");
        await dynamoDbClient.PutItemAsync(request);
        context.Logger.LogInformation("Successfully saved to DynamoDB");
    }

    private static Dictionary<string, string> GetCommonHeaders()
    {
        return new Dictionary<string, string>
        {
            { "Content-Type", "application/json" },
            { "Access-Control-Allow-Origin", "*" }
        };
    }

    private static APIGatewayProxyResponse CreateErrorResponse(int statusCode, string message)
    {
        return new APIGatewayProxyResponse
        {
            StatusCode = statusCode,
            Body = JsonSerializer.Serialize(new { message }),
            Headers = GetCommonHeaders()
        };
    }
}
