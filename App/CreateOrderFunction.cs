using System.IO;
using System.Net;
using System.Threading.Tasks;
using App.Dtos;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Extensions.Logging;
using Microsoft.OpenApi.Models;
using Newtonsoft.Json;

namespace App.Order
{
    public class CreateOrderFunction
    {
        [FunctionName("CreateOrderFunction")]
        [OpenApiOperation(operationId: "Run", tags: new[] { "Order" })]
        [OpenApiRequestBody(contentType: "application/json; charset=utf-8", bodyType: typeof(CreateOrderDto), Description = "Create order Request", Required = true)]
        [OpenApiResponseWithBody(statusCode: HttpStatusCode.OK, contentType: "text/plain", bodyType: typeof(string), Description = "The OK response")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = null)] HttpRequest req,
            [Queue("order-queue"),StorageAccount("AzureWebJobsStorage")] ICollector<string> queue,
            ILogger log)
        {
            log.LogInformation("Creating the order ...");

            var content = await new StreamReader(req.Body).ReadToEndAsync();

            CreateOrderDto createOrderDto = JsonConvert.DeserializeObject<CreateOrderDto>(content);
            
            var order = new Models.Order(createOrderDto.Value);

            log.LogInformation("Order created");

            log.LogInformation("Sending message to queue ...");

            var message = JsonConvert.SerializeObject(order);

            queue.Add(message);
            
            log.LogInformation("Message sent");

            return new OkObjectResult(message);
        }
    }
}

