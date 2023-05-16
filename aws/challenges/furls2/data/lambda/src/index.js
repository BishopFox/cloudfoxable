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
                </style>
            </head>
            <body>
                <h1>FLAG{furls2::WhoCanExploitTheThingYouFound:PLACEHOLDER}</h1>
                <p><strong>Pay attention because this is important.</strong></p>
                <p>You found this flag because you discovered some credentials in an environment variable and you figured out that they could be used on this function. Nice work!</p>
                <p>So what now? You can certainly point out that it's a bad practice to put secrets in environment variables and that a secret solution like Secret Manager or Session Manager parameters should be used instead.</p>
                <p>However, as a penetration tester, what's really important now is to figure out WHO has access to this secret. For example, if the only people who have access to this environment variable you just found are Administrators and you, the penetration tester who requested SecurityAudit access, what's the risk? Barely any!</p>
                <p>On the other hand, if you can find a principal that can access that secret who clearly should not be able to access this secret, now you just put meaning to this sweet finding you have.</p>
                <p>So as your last challenge here, use the permissions command and replace PLACEHOLDER in the flag with the name (just the name, not the whole ARN) of the one role that can access this flag!</p>
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
