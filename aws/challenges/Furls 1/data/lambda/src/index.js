// index.js
exports.handler = async (event) => {
    const secretFlag = "FLAG{furls1::function_urls_can_be_accidentally_expose_internal_data}";

    const response = {
      statusCode: 200,
      body: JSON.stringify({
        flag: secretFlag
      }),
    };
    return response;
  };