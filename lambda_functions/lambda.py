import boto3
import decimal
import json
import os

DYNAMODB_ENDPOINT = f"http://{os.environ['LOCALSTACK_HOSTNAME']}:4566"

def replace_decimals(obj):
    if isinstance(obj, list):
        for i in range(len(obj)):
            obj[i] = replace_decimals(obj[i])
        return obj
    elif isinstance(obj, dict):
        for k, v in obj.items():
            obj[k] = replace_decimals(v)
        return obj
    elif isinstance(obj, decimal.Decimal):
        if obj % 1 == 0:
            return int(obj)
        else:
            return float(obj)
    else:
        return obj

def lambda_handler(event, context):
    """
    Accepts an action and a single number, performs the specified action on the number,
    and returns the result. The only allowable action is 'increment'.

    :param event: The event dict that contains the parameters sent when the function
                  is invoked.
    :param context: The context in which the function is called.
    :return: The result of the action.
    """

    body = "You made it!"
    args = event.get("queryStringParameters")

    if args is not None:
        param = args.get("parameter", None)
        customer_id = args.get("customer", None)
        metadata = args.get("metadata", "")
    

        if param is not None and customer_id is not None:
            dynamodb = boto3.resource("dynamodb", endpoint_url=DYNAMODB_ENDPOINT)
            dynamo_wx_table = dynamodb.Table("WxChangeSample")
            dynamo_wx_table.put_item(Item={"WeatherParameter": param, "CustomerId": int(customer_id), "MetaData": metadata})

            # scan all items and return to see that our new one made it
            table_results = dynamo_wx_table.scan().get("Items")

            # need to convert dynamo's decimal types to ints or floats to be jsonified properly. You could also make a custom encoder to pass to json.dumps
            converted_results = replace_decimals(table_results)

            # create a dictionary to hold our response to be converted into json
            body = {"Action": f"Added {param} for customer {customer_id}",
                    "Current_items": json.dumps(converted_results)} 
    
        else:
            body = "Error, did not pass in proper arguments. Requires parameter and customer"
    
    else:
            body = "Error, did not pass in any arguments. Requires parameter and customer"
            
    headers = {
                "Content-Type": "application/json",
                "Content-Length": str(len(body)),
            }

    return {
        "statusCode": 200,
        "headers": headers,
        "body": json.dumps(body)
        }