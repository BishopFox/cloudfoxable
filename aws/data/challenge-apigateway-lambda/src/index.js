// index.js
exports.handler = async (event) => {
    const secretFlag = "flag{internal_apis_can_have_sensitive_data}";

    const response = {
      statusCode: 200,
      body: JSON.stringify({
        flag: secretFlag
      }),
    };
    return response;
  };