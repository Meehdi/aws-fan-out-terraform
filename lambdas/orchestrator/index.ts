import { DynamoDBClient, GetItemCommand } from "@aws-sdk/client-dynamodb";
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";
import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

const dynamoClient = new DynamoDBClient({});
const snsClient = new SNSClient({});

const TABLE_NAME = process.env.TABLE_NAME!;
const SNS_TOPIC_ARN = process.env.SNS_TOPIC_ARN!;

interface UserData {
    username: string;
    email: string;
}

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    console.log("Event received:", JSON.stringify(event, null, 2));

    try {
        // Parse request body
        const body: UserData = JSON.parse(event.body || "{}");
        const { username, email } = body;

        // Validate input
        if (!username || !email) {
            return {
                statusCode: 400,
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    message: "Missing required fields: username and email"
                })
            };
        }

        // Check if email already exists in DynamoDB
        const getItemParams = {
            TableName: TABLE_NAME,
            Key: {
                email: { S: email }
            }
        };

        const existingUser = await dynamoClient.send(new GetItemCommand(getItemParams));

        if (existingUser.Item) {
            console.log("User already exists:", email);
            return {
                statusCode: 409,
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    message: "User with this email already exists"
                })
            };
        }

        // Publish message to SNS topic (fan-out)
        const messageData = {
            username,
            email,
            timestamp: new Date().toISOString()
        };

        const publishParams = {
            TopicArn: SNS_TOPIC_ARN,
            Message: JSON.stringify(messageData),
            Subject: "New User Registration"
        };

        await snsClient.send(new PublishCommand(publishParams));
        console.log("Message published to SNS:", messageData);

        return {
            statusCode: 201,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                message: "User registration initiated successfully",
                user: { username, email }
            })
        };

    } catch (error) {
        console.error("Error:", error);
        return {
            statusCode: 500,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                message: "Internal server error",
                error: error instanceof Error ? error.message : "Unknown error"
            })
        };
    }
};