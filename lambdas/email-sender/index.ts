import { SESClient, SendEmailCommand } from "@aws-sdk/client-ses";
import { SQSEvent } from "aws-lambda";

const sesClient = new SESClient({});
const SENDER_EMAIL = process.env.SENDER_EMAIL || "noreply@example.com";

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

            console.log("Sending email to:", userData.email);

            // Send email via SES
            const emailParams = {
                Source: SENDER_EMAIL,
                Destination: {
                    ToAddresses: [userData.email]
                },
                Message: {
                    Subject: {
                        Data: "Welcome to Our Platform!"
                    },
                    Body: {
                        Text: {
                            Data: `Hello ${userData.username},\n\nWelcome to our platform! Your account has been successfully created.\n\nEmail: ${userData.email}\nRegistered at: ${userData.timestamp}\n\nBest regards,\nThe Team`
                        },
                        Html: {
                            Data: `
                <html>
                  <body>
                    <h2>Hello ${userData.username},</h2>
                    <p>Welcome to our platform! Your account has been successfully created.</p>
                    <ul>
                      <li><strong>Email:</strong> ${userData.email}</li>
                      <li><strong>Registered at:</strong> ${userData.timestamp}</li>
                    </ul>
                    <p>Best regards,<br/>The Team</p>
                  </body>
                </html>
              `
                        }
                    }
                }
            };

            await sesClient.send(new SendEmailCommand(emailParams));
            console.log("Email sent successfully to:", userData.email);
        }

        return {
            statusCode: 200,
            body: JSON.stringify({ message: "Emails sent successfully" })
        };

    } catch (error) {
        console.error("Error sending email:", error);
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: "Processed with errors",
                error: error instanceof Error ? error.message : "Unknown error"
            })
        };
    }
};