const username = 'admin';
const password = 'NotSummer2023';

exports.handler = async (event) => {
    const query = event.queryStringParameters;

    let message;
    let statusCode = 200;

    if (query && query.username === username && query.password === password) {
        message = `
        <!DOCTYPE html>
        <html>
        <head>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    line-height: 1.6;
                }
                h1 {
                    color: red;
                }
                p {
                    margin-bottom: 10px;
                }
            </style>
        </head>
        <body>
            <h1>FLAG{furls2::WhoCanExploitTheThingYouFound:PLACEHOLDER}</h1>
            <p><strong>Pay attention because this is important.</strong></p>
            <p>You found this flag because you discovered some credentials in an environment variable and realized that they could be used with this function. Great job!</p>
            <p>Now, what should you do next? While it's true that storing secrets in environment variables is considered bad practice, it's even more crucial for a penetration tester like you to determine WHO can access this secret.</p>
            <p>For instance, if only Administrators and you (the penetration tester who requested SecurityAudit access) have access to this environment variable, the risk is minimal.</p>
            <p>However, if you can find a principal who shouldn't have access to this secret but can still access it, then your discovery becomes significant.</p>
            <p>As your final challenge, use the 'permissions' command and replace 'PLACEHOLDER' in the flag with the name (just the name, not the entire ARN) of the role that can access this flag!</p>
        </body>
        </html>      
        `;
    } else {
        message = 'To authenticate, send a GET request with the following parameters: username=[username]&password=[password].<br><br>You should check out the furls2 challenge for more information.';
    }

    const response = {
        statusCode: statusCode,
        headers: {
            'Content-Type': 'text/html'
        },
        body: message
    };

    return response;
};
