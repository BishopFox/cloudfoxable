// create lambda handler that accepts and event and sends it to SNS

exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var message = event.Records[0].Sns.Message;
    var SNSparams = {
        Message: message,
        TopicArn: process.env.TOPIC_ARN
    };
    sns.publish(SNSparams, context.done);
    var SQSparams = {
        MessageBody: message,
        QueueUrl: process.env.QUEUE_URL
    };
    sqs.sendMessage(SQSparams, context.done);
    }
//
