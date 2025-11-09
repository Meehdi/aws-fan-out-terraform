import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";
import { SQSEvent } from "aws-lambda";

const dynamoClient = new DynamoDBClient({});
const TABLE_NAME = process.env.TABLE_NAME!;

interface UserMessage {
    username: string;
    email: string;
    timestamp: string;
}

export const handler = async (event: SQSEvent): Promise<{ statusCode: number; body: string }> => {
    console.log("Event received:", JSON.stringify(event, null, 2));

    try {
        // Process each SQS record
        for (const record of event.Records) {
            // Parse SNS message from SQS
            const snsMessage = JSON.parse(record.body);
            const userData: UserMessage = JSON.parse(snsMessage.Message);

            console.log("Processing user data:", userData);

            // Write to DynamoDB
            const putItemParams = {
                TableName: TABLE_NAME,
                Item: {
                    email: { S: userData.email },
                    username: { S: userData.username },
                    createdAt: { S: userData.timestamp }
                }
            };

            await dynamoClient.send(new PutItemCommand(putItemParams));
            console.log("User saved to DynamoDB:", userData.email);
        }

        return {
            statusCode: 200,
            body: JSON.stringify({ message: "Users processed successfully" })
        };

    } catch (error) {
        console.error("Error processing records:", error);
        throw error; // Let SQS retry
    }
};