// index.js
exports.handler = async (event) => {
    const secretFlag = "flag{function_urls_can_be_dangerous}";

    const response = {
      statusCode: 200,
      body: JSON.stringify({
        flag: secretFlag
      }),
    };
    return response;
  };